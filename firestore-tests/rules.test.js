// firestore.rules 에뮬레이터 테스트
//
// 실행: cd firestore-tests && npm install && npm test   (Java 21 필요)
// 프로젝트 ID 가 demo- 로 시작하면 에뮬레이터는 실제 Firebase 프로젝트에 접속하지 않는다.
//
// "app:" 으로 시작하는 테스트는 앱 코드(*Repository.swift)가 보내는 쓰기를 그대로 옮긴 것이다.
// 규칙을 바꿨는데 이 테스트가 깨지면 출시된 앱이 깨진다는 뜻이다.
// "attack:" 테스트는 막아야 하는 쓰기다.

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
    assertFails,
    assertSucceeds,
    initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
    Timestamp,
    addDoc,
    arrayRemove,
    arrayUnion,
    collection,
    deleteDoc,
    deleteField,
    doc,
    getDoc,
    getDocs,
    limit,
    orderBy,
    query,
    runTransaction,
    serverTimestamp,
    setDoc,
    updateDoc,
    where,
} from 'firebase/firestore';

const ALICE = 'alice-uid';   // 그룹 생성자
const BOB = 'bob-uid';       // 같은 가족
const MALLORY = 'mallory-uid'; // 공격자 (익명 로그인만 한 임의 사용자)
const GROUP_ID = 'groupDocId0000000001';
const CODE = 'ABC234';

let env;

before(async () => {
    env = await initializeTestEnvironment({
        projectId: 'demo-everydomath',
        // RULES_PATH 로 다른 규칙 파일(예: 배포 중인 이전 버전)을 대조할 수 있다
        firestore: { rules: readFileSync(process.env.RULES_PATH ?? new URL('../firestore.rules', import.meta.url), 'utf8') },
    });
});

after(async () => {
    await env?.cleanup();
});

beforeEach(async () => {
    await env.clearFirestore();
});

const db = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();

/** 규칙을 우회해 초기 상태를 넣는다 */
async function seed(path, data) {
    await env.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), path), data);
    });
}

async function seedGroup() {
    await seed(`familyGroups/${GROUP_ID}`, {
        id: GROUP_ID,
        groupCode: CODE,
        memberIds: [ALICE, BOB],
        memberNames: { [ALICE]: '엄마', [BOB]: '민수' },
        scores: { [ALICE]: 300, [BOB]: 500 },
        createdAt: Timestamp.now(),
        createdBy: ALICE,
    });
}

// ────────────────────────────────────────────────────────────
// 앱 쓰기 경로 재현 (FamilyGroupRepository.swift)
// ────────────────────────────────────────────────────────────

/** createGroup(uid:nickname:) */
function appCreateGroup(fs, uid, nickname) {
    return setDoc(doc(fs, 'familyGroups', GROUP_ID), {
        id: GROUP_ID,
        groupCode: CODE,
        memberIds: [uid],
        memberNames: { [uid]: nickname },
        scores: { [uid]: 0 },
        createdAt: Timestamp.now(),
        createdBy: uid,
    });
}

/** joinGroup(code:uid:nickname:) */
async function appJoinGroup(fs, code, uid, nickname) {
    const snap = await getDocs(query(collection(fs, 'familyGroups'), where('groupCode', '==', code), limit(1)));
    if (snap.empty) throw new Error('notFound');
    await updateDoc(snap.docs[0].ref, {
        memberIds: arrayUnion(uid),
        [`memberNames.${uid}`]: nickname,
        [`scores.${uid}`]: 0,
    });
}

/** updateScore(groupId:uid:score:) */
async function appUpdateScore(fs, uid, score) {
    const ref = doc(fs, 'familyGroups', GROUP_ID);
    const snap = await getDoc(ref);
    const existing = snap.data()?.scores?.[uid];
    if (existing !== undefined && existing >= score) return;
    await updateDoc(ref, { [`scores.${uid}`]: score });
}

/** leaveGroup(groupId:uid:) */
function appLeaveGroup(fs, uid) {
    return updateDoc(doc(fs, 'familyGroups', GROUP_ID), {
        memberIds: arrayRemove(uid),
        [`memberNames.${uid}`]: deleteField(),
        [`scores.${uid}`]: deleteField(),
    });
}

/** RemoteLeaderboardRepository.uploadScore */
function appUploadScore(fs, uid, score, { grade = 3, gameGrade = 'A', correctCount = 18, nickname = '민수' } = {}) {
    const ref = doc(fs, 'leaderboard', uid);
    return runTransaction(fs, async (tx) => {
        const existing = await tx.get(ref);
        const best = existing.data()?.score ?? 0;
        if (score <= best) return;
        tx.set(ref, {
            userId: uid,
            nickname,
            grade,
            score,
            gameGrade,
            correctCount,
            updatedAt: serverTimestamp(),
        });
    });
}

// ────────────────────────────────────────────────────────────

describe('familyGroups — 앱 정상 경로', () => {
    test('app: 그룹 생성', async () => {
        await assertSucceeds(appCreateGroup(db(ALICE), ALICE, '엄마'));
    });

    test('app: 코드로 참여 (목록 쿼리 + arrayUnion)', async () => {
        await seedGroup();
        await assertSucceeds(appJoinGroup(db(MALLORY), CODE, MALLORY, '이모'));
        const snap = await getDoc(doc(db(MALLORY), 'familyGroups', GROUP_ID));
        if (!snap.data().memberIds.includes(MALLORY)) throw new Error('참여가 반영되지 않음');
    });

    test('app: 이미 멤버인 사람이 다시 참여 (점수 0 으로 초기화됨)', async () => {
        await seedGroup();
        await assertSucceeds(appJoinGroup(db(BOB), CODE, BOB, '민수'));
    });

    test('app: 그룹 리더보드 단건 조회', async () => {
        await seedGroup();
        await assertSucceeds(getDoc(doc(db(BOB), 'familyGroups', GROUP_ID)));
    });

    test('app: 내 점수 갱신', async () => {
        await seedGroup();
        await assertSucceeds(appUpdateScore(db(BOB), BOB, 900));
    });

    test('app: 만점 1000 갱신', async () => {
        await seedGroup();
        await assertSucceeds(appUpdateScore(db(BOB), BOB, 1000));
    });

    test('app: 멤버 탈퇴', async () => {
        await seedGroup();
        await assertSucceeds(appLeaveGroup(db(BOB), BOB));
    });

    test('app: 생성자 탈퇴 후 마지막 멤버 탈퇴 (빈 목록/맵)', async () => {
        await seedGroup();
        await assertSucceeds(appLeaveGroup(db(ALICE), ALICE));
        await assertSucceeds(appLeaveGroup(db(BOB), BOB));
    });

    test('app: 탈퇴했다가 다시 참여', async () => {
        await seedGroup();
        await assertSucceeds(appLeaveGroup(db(BOB), BOB));
        await assertSucceeds(appJoinGroup(db(BOB), CODE, BOB, '민수'));
    });
});

describe('familyGroups — 막아야 하는 쓰기', () => {
    test('attack: 로그인 없이 조회', async () => {
        await seedGroup();
        await assertFails(getDoc(doc(anon(), 'familyGroups', GROUP_ID)));
    });

    test('attack: 다른 멤버를 쫓아낸다', async () => {
        await seedGroup();
        await assertFails(updateDoc(doc(db(MALLORY), 'familyGroups', GROUP_ID), {
            memberIds: arrayRemove(BOB),
            [`memberNames.${BOB}`]: deleteField(),
            [`scores.${BOB}`]: deleteField(),
        }));
    });

    test('attack: 멤버가 다른 멤버를 쫓아낸다', async () => {
        await seedGroup();
        await assertFails(appLeaveGroup(db(ALICE), BOB));
    });

    test('attack: 남의 별명을 바꾼다', async () => {
        await seedGroup();
        await assertFails(updateDoc(doc(db(MALLORY), 'familyGroups', GROUP_ID), {
            [`memberNames.${BOB}`]: '바보',
        }));
    });

    test('attack: 같은 그룹 멤버가 남의 점수를 깎는다', async () => {
        await seedGroup();
        await assertFails(updateDoc(doc(db(ALICE), 'familyGroups', GROUP_ID), {
            [`scores.${BOB}`]: 0,
        }));
    });

    test('attack: 내 점수를 상한 이상으로 올린다', async () => {
        await seedGroup();
        await assertFails(updateDoc(doc(db(BOB), 'familyGroups', GROUP_ID), {
            [`scores.${BOB}`]: 99999,
        }));
    });

    test('attack: 점수에 숫자가 아닌 값', async () => {
        await seedGroup();
        await assertFails(updateDoc(doc(db(BOB), 'familyGroups', GROUP_ID), {
            [`scores.${BOB}`]: '1000',
        }));
    });

    test('attack: 참여하면서 점수를 0 이 아닌 값으로 넣는다', async () => {
        await seedGroup();
        await assertFails(updateDoc(doc(db(MALLORY), 'familyGroups', GROUP_ID), {
            memberIds: arrayUnion(MALLORY),
            [`memberNames.${MALLORY}`]: '이모',
            [`scores.${MALLORY}`]: 1000,
        }));
    });

    test('attack: 참여 없이 리더보드에 이름·점수만 끼워 넣는다', async () => {
        await seedGroup();
        await assertFails(updateDoc(doc(db(MALLORY), 'familyGroups', GROUP_ID), {
            [`memberNames.${MALLORY}`]: '유령',
            [`scores.${MALLORY}`]: 0,
        }));
    });

    test('attack: 남을 대신 참여시킨다', async () => {
        await seedGroup();
        await assertFails(updateDoc(doc(db(MALLORY), 'familyGroups', GROUP_ID), {
            memberIds: arrayUnion('victim-uid'),
            [`memberNames.victim-uid`]: '피해자',
            [`scores.victim-uid`]: 0,
        }));
    });

    test('attack: 별명 없이 memberIds 만 추가', async () => {
        await seedGroup();
        await assertFails(updateDoc(doc(db(MALLORY), 'familyGroups', GROUP_ID), {
            memberIds: arrayUnion(MALLORY),
        }));
    });

    test('attack: 21자 이상 별명으로 참여', async () => {
        await seedGroup();
        await assertFails(appJoinGroup(db(MALLORY), CODE, MALLORY, 'x'.repeat(21)));
    });

    test('attack: 초대 코드를 바꾼다', async () => {
        await seedGroup();
        await assertFails(updateDoc(doc(db(ALICE), 'familyGroups', GROUP_ID), { groupCode: 'ZZZ999' }));
    });

    test('attack: 생성자를 바꾼다', async () => {
        await seedGroup();
        await assertFails(updateDoc(doc(db(MALLORY), 'familyGroups', GROUP_ID), { createdBy: MALLORY }));
    });

    test('attack: 멤버 맵을 통째로 덮어쓴다', async () => {
        await seedGroup();
        await assertFails(updateDoc(doc(db(ALICE), 'familyGroups', GROUP_ID), {
            memberIds: [ALICE],
            memberNames: { [ALICE]: '엄마' },
            scores: { [ALICE]: 300 },
        }));
    });

    test('attack: 그룹 문서 삭제', async () => {
        await seedGroup();
        await assertFails(deleteDoc(doc(db(ALICE), 'familyGroups', GROUP_ID)));
    });

    test('attack: 다른 사람 명의로 그룹 생성', async () => {
        await assertFails(appCreateGroup(db(MALLORY), ALICE, '엄마'));
    });

    test('attack: 높은 점수를 넣은 채로 그룹 생성', async () => {
        await assertFails(setDoc(doc(db(ALICE), 'familyGroups', GROUP_ID), {
            id: GROUP_ID,
            groupCode: CODE,
            memberIds: [ALICE],
            memberNames: { [ALICE]: '엄마' },
            scores: { [ALICE]: 99999 },
            createdAt: Timestamp.now(),
            createdBy: ALICE,
        }));
    });

    test('attack: 다른 uid 의 별명을 넣은 채로 그룹 생성', async () => {
        await assertFails(setDoc(doc(db(ALICE), 'familyGroups', GROUP_ID), {
            id: GROUP_ID,
            groupCode: CODE,
            memberIds: [ALICE],
            memberNames: { [ALICE]: '엄마', [BOB]: '민수' },
            scores: { [ALICE]: 0 },
            createdAt: Timestamp.now(),
            createdBy: ALICE,
        }));
    });

    test('attack: limit 2 이상 목록 조회', async () => {
        await seedGroup();
        await assertFails(getDocs(query(collection(db(MALLORY), 'familyGroups'), limit(2))));
    });

    // 규칙만으로는 막을 수 없는 경로. 고쳐지면 이 테스트가 깨지므로 그때 assertFails 로 바꾼다.
    test('known gap: 필터 없는 limit(1) 목록 조회는 여전히 통과 (앱 구조 변경 필요)', async () => {
        await seedGroup();
        await assertSucceeds(getDocs(query(collection(db(MALLORY), 'familyGroups'), limit(1))));
    });
});

// ────────────────────────────────────────────────────────────

describe('leaderboard', () => {
    test('app: 첫 점수 업로드', async () => {
        await assertSucceeds(appUploadScore(db(BOB), BOB, 700));
    });

    test('app: 최고 점수 갱신', async () => {
        await appUploadScore(db(BOB), BOB, 700);
        await assertSucceeds(appUploadScore(db(BOB), BOB, 800));
    });

    test('app: 전체/학년별 상위 50 조회와 순위 집계 쿼리', async () => {
        await appUploadScore(db(BOB), BOB, 700);
        const fs = db(ALICE);
        await assertSucceeds(getDocs(query(collection(fs, 'leaderboard'), orderBy('score', 'desc'), limit(50))));
        await assertSucceeds(getDocs(query(collection(fs, 'leaderboard'), where('grade', '==', 3),
            orderBy('score', 'desc'), limit(50))));
        await assertSucceeds(getDocs(query(collection(fs, 'leaderboard'), where('score', '>', 500))));
    });

    test('attack: 로그인 없이 조회', async () => {
        await assertFails(getDocs(query(collection(anon(), 'leaderboard'), limit(50))));
    });

    test('attack: 남의 기록을 덮어쓴다', async () => {
        await assertFails(appUploadScore(db(MALLORY), BOB, 900));
    });

    test('attack: 상한 초과 점수', async () => {
        await assertFails(appUploadScore(db(BOB), BOB, 1001));
    });

    test('attack: 점수를 깎는다', async () => {
        await appUploadScore(db(BOB), BOB, 700);
        await assertFails(setDoc(doc(db(BOB), 'leaderboard', BOB), {
            userId: BOB, nickname: '민수', grade: 3, score: 100, gameGrade: 'D',
            correctCount: 2, updatedAt: serverTimestamp(),
        }));
    });

    test('attack: updatedAt 을 클라이언트 시각으로 위조', async () => {
        await assertFails(setDoc(doc(db(BOB), 'leaderboard', BOB), {
            userId: BOB, nickname: '민수', grade: 3, score: 700, gameGrade: 'A',
            correctCount: 18, updatedAt: Timestamp.fromDate(new Date('2030-01-01')),
        }));
    });

    test('app: 「데이터 초기화」가 내 기록을 지운다 (deleteMyEntry)', async () => {
        await appUploadScore(db(BOB), BOB, 700);
        await assertSucceeds(deleteDoc(doc(db(BOB), 'leaderboard', BOB)));
    });

    test('attack: 남의 기록 삭제', async () => {
        await appUploadScore(db(BOB), BOB, 700);
        await assertFails(deleteDoc(doc(db(MALLORY), 'leaderboard', BOB)));
    });
});

// ────────────────────────────────────────────────────────────

describe('reports', () => {
    const report = (reporterId) => ({
        reporterId,
        reportedUserId: BOB,
        reportedNickname: '민수',
        reason: 'inappropriate_name',
        createdAt: serverTimestamp(),
    });

    test('app: 신고 남기기', async () => {
        await assertSucceeds(addDoc(collection(db(ALICE), 'reports'), report(ALICE)));
    });

    test('attack: 신고 열람', async () => {
        await assertFails(getDocs(query(collection(db(ALICE), 'reports'), limit(1))));
    });

    test('attack: 신고자 사칭', async () => {
        await assertFails(addDoc(collection(db(MALLORY), 'reports'), report(ALICE)));
    });
});

describe('그 밖의 경로', () => {
    test('attack: 규칙에 없는 컬렉션 쓰기', async () => {
        await assertFails(setDoc(doc(db(ALICE), 'users/alice'), { a: 1 }));
    });
});
