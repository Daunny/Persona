import React, { useState, useEffect, useCallback } from 'react';
import { initializeApp } from 'firebase/app';
import { getAuth, signInAnonymously, signInWithCustomToken, onAuthStateChanged } from 'firebase/auth';
import { getFirestore, doc, setDoc, getDoc, collection, query, getDocs, writeBatch } from 'firebase/firestore';

// Updated data for questions and MBTI results based on new axes
const questionsData = [
  // Axis 1: 접근 방식 (Approach Style) - P: Proactive ↔ R: Responsive
  {
    id: 'q1',
    topic: '접근 방식',
    text: '새로운 잠재고객을 발굴할 때 나는...',
    options: [
      { id: 'q1o1', text: '적극적으로 리스트를 만들어 직접 연락한다', score: { APPROACH: 2 } },
      { id: 'q1o2', text: '네트워킹 이벤트에서 자연스럽게 접근한다', score: { APPROACH: 1 } },
      { id: 'q1o3', text: '상황에 따라 두 방법을 모두 활용한다', score: { APPROACH: 0 } },
      { id: 'q1o4', text: '주로 인바운드 문의에 대응한다', score: { APPROACH: -1 } },
      { id: 'q1o5', text: '추천이나 소개를 통해서만 만난다', score: { APPROACH: -2 } },
    ],
  },
  {
    id: 'q2',
    topic: '접근 방식',
    text: '하루 업무를 시작할 때 가장 먼저 하는 일은...',
    options: [
      { id: 'q2o1', text: '신규 고객에게 연락할 리스트 확인', score: { APPROACH: 2 } },
      { id: 'q2o2', text: '오늘 해야 할 영업 활동 계획 수립', score: { APPROACH: 1 } },
      { id: 'q2o3', text: '이메일과 메시지 확인 후 우선순위 정리', score: { APPROACH: 0 } },
      { id: 'q2o4', text: '들어온 문의사항 검토 및 답변 준비', score: { APPROACH: -1 } },
      { id: 'q2o5', text: '기존 고객 상태 점검 및 팔로우업', score: { APPROACH: -2 } },
    ],
  },
  {
    id: 'q3',
    topic: '접근 방식',
    text: '영업 미팅을 잡는 방식은...',
    options: [
      { id: 'q3o1', text: '내가 먼저 여러 채널로 적극 제안', score: { APPROACH: 2 } },
      { id: 'q3o2', text: '고객이 관심 보일 때 빠르게 제안', score: { APPROACH: 1 } },
      { id: 'q3o3', text: '상황과 고객에 따라 유연하게 대응', score: { APPROACH: 0 } },
      { id: 'q3o4', text: '고객이 원하는 시간에 맞춰 조율', score: { APPROACH: -1 } },
      { id: 'q3o5', text: '고객이 먼저 미팅을 요청할 때만', score: { APPROACH: -2 } },
    ],
  },
  {
    id: 'q4',
    topic: '접근 방식',
    text: '콜드 콜(Cold Call)에 대한 나의 생각은...',
    options: [
      { id: 'q4o1', text: '영업의 필수 요소, 매일 일정 수량 실행', score: { APPROACH: 2 } },
      { id: 'q4o2', text: '필요시 활용하는 유용한 도구', score: { APPROACH: 1 } },
      { id: 'q4o3', text: '효과적이지만 부담스러운 방법', score: { APPROACH: 0 } },
      { id: 'q4o4', text: '가능하면 피하고 싶은 방법', score: { APPROACH: -1 } },
      { id: 'q4o5', text: '절대 하지 않는 구시대적 방법', score: { APPROACH: -2 } },
    ],
  },
  {
    id: 'q5',
    topic: '접근 방식',
    text: '마케팅 리드(Lead)를 받았을 때...',
    options: [
      { id: 'q5o1', text: '즉시 연락해서 추가 니즈 파악', score: { APPROACH: 2 } },
      { id: 'q5o2', text: '정보 분석 후 맞춤 제안 준비', score: { APPROACH: 1 } },
      { id: 'q5o3', text: '리드 품질에 따라 대응 수준 결정', score: { APPROACH: 0 } },
      { id: 'q5o4', text: '고객이 추가 정보 요청시 대응', score: { APPROACH: -1 } },
      { id: 'q5o5', text: '정말 관심 있는 고객만 선별 대응', score: { APPROACH: -2 } },
    ],
  },
  {
    id: 'q6',
    topic: '접근 방식',
    text: '영업 성과를 높이기 위한 방법으로...',
    options: [
      { id: 'q6o1', text: '더 많은 고객에게 적극적으로 접근', score: { APPROACH: 2 } },
      { id: 'q6o2', text: '타겟 고객을 정교하게 선별하여 접근', score: { APPROACH: 1 } },
      { id: 'q6o3', text: '접근 횟수와 품질의 균형 추구', score: { APPROACH: 0 } },
      { id: 'q6o4', text: '들어오는 문의의 전환율 극대화', score: { APPROACH: -1 } },
      { id: 'q6o5', text: '기존 고객의 추가 구매 유도', score: { APPROACH: -2 } },
    ],
  },
  {
    id: 'q7',
    topic: '접근 방식',
    text: '업계 네트워킹 행사에 참석했을 때...',
    options: [
      { id: 'q7o1', text: '최대한 많은 사람과 명함 교환', score: { APPROACH: 2 } },
      { id: 'q7o2', text: '미리 타겟한 핵심 인물 집중 공략', score: { APPROACH: 1 } },
      { id: 'q7o3', text: '자연스러운 대화 속에서 기회 모색', score: { APPROACH: 0 } },
      { id: 'q7o4', text: '부스에서 찾아오는 사람들 응대', score: { APPROACH: -1 } },
      { id: 'q7o5', text: '기존 고객과의 관계 강화에 집중', score: { APPROACH: -2 } },
    ],
  },
  {
    id: 'q8',
    topic: '접근 방식',
    text: '신제품 출시 시 나의 영업 전략은...',
    options: [
      { id: 'q8o1', text: '전체 고객 대상 대규모 캠페인', score: { APPROACH: 2 } },
      { id: 'q8o2', text: '얼리어답터 그룹 집중 공략', score: { APPROACH: 1 } },
      { id: 'q8o3', text: '단계적 확산 전략 수립', score: { APPROACH: 0 } },
      { id: 'q8o4', text: '관심 고객의 문의 대응 준비', score: { APPROACH: -1 } },
      { id: 'q8o5', text: '기존 충성 고객 대상 우선 안내', score: { APPROACH: -2 } },
    ],
  },
  {
    id: 'q9',
    topic: '접근 방식',
    text: '경쟁사 고객을 공략할 때...',
    options: [
      { id: 'q9o1', text: '적극적으로 전환 제안 제시', score: { APPROACH: 2 } },
      { id: 'q9o2', text: '불만 사항 파악 후 대안 제시', score: { APPROACH: 1 } },
      { id: 'q9o3', text: '장기적 관점에서 관계 구축', score: { APPROACH: 0 } },
      { id: 'q9o4', text: '고객이 먼저 관심 보일 때까지 대기', score: { APPROACH: -1 } },
      { id: 'q9o5', text: '윤리적 이유로 접근하지 않음', score: { APPROACH: -2 } },
    ],
  },
  {
    id: 'q10',
    topic: '접근 방식',
    text: '분기 목표 달성이 어려울 때...',
    options: [
      { id: 'q10o1', text: '신규 고객 발굴 활동 2배 증가', score: { APPROACH: 2 } },
      { id: 'q10o2', text: '고확률 기회에 역량 집중', score: { APPROACH: 1 } },
      { id: 'q10o3', text: '원인 분석 후 전략 수정', score: { APPROACH: 0 } },
      { id: 'q10o4', text: '진행 중인 딜 클로징에 집중', score: { APPROACH: -1 } },
      { id: 'q10o5', text: '다음 분기를 위한 파이프라인 구축', score: { APPROACH: -2 } },
    ],
  },
  {
    id: 'q11',
    topic: '접근 방식',
    text: 'CRM 시스템 활용 방식은...',
    options: [
      { id: 'q11o1', text: '모든 잠재고객 정보 상세 입력', score: { APPROACH: 2 } },
      { id: 'q11o2', text: '핵심 고객 중심 선별 관리', score: { APPROACH: 1 } },
      { id: 'q11o3', text: '영업 단계별 체계적 관리', score: { APPROACH: 0 } },
      { id: 'q11o4', text: '인바운드 리드 추적 위주', score: { APPROACH: -1 } },
      { id: 'q11o5', text: '필수 정보만 최소한 입력', score: { APPROACH: -2 } },
    ],
  },
  {
    id: 'q12',
    topic: '접근 방식',
    text: '영업 스타일을 한마디로 표현하면...',
    options: [
      { id: 'q12o1', text: '"사냥꾼" - 적극적으로 기회 추구', score: { APPROACH: 2 } },
      { id: 'q12o2', text: '"농부" - 씨앗을 뿌리고 가꾸기', score: { APPROACH: 1 } },
      { id: 'q12o3', text: '"어부" - 적절한 미끼로 유인', score: { APPROACH: 0 } },
      { id: 'q12o4', text: '"목자" - 찾아온 양들을 돌봄', score: { APPROACH: -1 } },
      { id: 'q12o5', text: '"정원사" - 기존 정원을 가꾸기', score: { APPROACH: -2 } },
    ],
  },

  // Axis 2: 가치 전달 방식 (Value Delivery) - S: Solution-focused ↔ F: Service-focused
  {
    id: 'q13',
    topic: '가치 전달 방식',
    text: '첫 미팅에서 가장 많은 시간을 할애하는 것은...',
    options: [
      { id: 'q13o1', text: '고객의 현재 상황과 문제점 파악', score: { VALUE: 2 } },
      { id: 'q13o2', text: '고객 니즈와 우리 솔루션 매칭', score: { VALUE: 1 } },
      { id: 'q13o3', text: '고객 이해와 서비스 소개 균형', score: { VALUE: 0 } },
      { id: 'q13o4', text: '우리 회사와 서비스 차별점 설명', score: { VALUE: -1 } },
      { id: 'q13o5', text: '서비스 기능과 구성 상세 설명', score: { VALUE: -2 } },
    ],
  },
  {
    id: 'q14',
    topic: '가치 전달 방식',
    text: '고객이 "왜 당신 서비스를 이용해야 하죠?"라고 물으면...',
    options: [
      { id: 'q14o1', text: '"먼저 고객님의 현재 과제를 들어보고 싶습니다"', score: { VALUE: 2 } },
      { id: 'q14o2', text: '"고객님 상황에 어떻게 도움되는지 설명드리겠습니다"', score: { VALUE: 1 } },
      { id: 'q14o3', text: '"저희 서비스의 장점과 고객님께 주는 가치를 말씀드리겠습니다"', score: { VALUE: 0 } },
      { id: 'q14o4', text: '"저희 서비스만의 독특한 특징을 보여드리겠습니다"', score: { VALUE: -1 } },
      { id: 'q14o5', text: '"업계 최고 수준의 서비스와 기능을 갖추고 있습니다"', score: { VALUE: -2 } },
    ],
  },
  {
    id: 'q15',
    topic: '가치 전달 방식',
    text: '제안서를 작성할 때 가장 중점을 두는 부분은...',
    options: [
      { id: 'q15o1', text: '고객 현황 분석 및 개선 방향', score: { VALUE: 2 } },
      { id: 'q15o2', text: '고객 니즈에 대한 맞춤 솔루션', score: { VALUE: 1 } },
      { id: 'q15o3', text: '문제 해결과 서비스 특징의 연결', score: { VALUE: 0 } },
      { id: 'q15o4', text: '서비스의 차별화된 가치 제안', score: { VALUE: -1 } },
      { id: 'q15o5', text: '상세한 서비스 구성과 기능 설명', score: { VALUE: -2 } },
    ],
  },
  {
    id: 'q16',
    topic: '가치 전달 방식',
    text: '경쟁사 대비 우위를 설명할 때...',
    options: [
      { id: 'q16o1', text: '고객 입장에서의 실질적 혜택 중심', score: { VALUE: 2 } },
      { id: 'q16o2', text: '고객 상황에 맞는 비교 포인트 제시', score: { VALUE: 1 } },
      { id: 'q16o3', text: '객관적 사실과 고객 가치 균형', score: { VALUE: 0 } },
      { id: 'q16o4', text: '우리 서비스의 우수한 기능 강조', score: { VALUE: -1 } },
      { id: 'q16o5', text: '기술적 구성과 성능 수치 비교', score: { VALUE: -2 } },
    ],
  },
  {
    id: 'q17',
    topic: '가치 전달 방식',
    text: '고객이 가격이 비싸다고 할 때...',
    options: [
      { id: 'q17o1', text: '"어떤 부분에서 부담을 느끼시는지 자세히 들어보겠습니다"', score: { VALUE: 2 } },
      { id: 'q17o2', text: '"투자 대비 얻으실 가치를 설명드리겠습니다"', score: { VALUE: 1 } },
      { id: 'q17o3', text: '"가격 대비 혜택을 분석해 보여드리겠습니다"', score: { VALUE: 0 } },
      { id: 'q17o4', text: '"이 가격이 합리적인 이유를 설명드리겠습니다"', score: { VALUE: -1 } },
      { id: 'q17o5', text: '"최고 품질에는 상응하는 가격이 책정됩니다"', score: { VALUE: -2 } },
    ],
  },
  {
    id: 'q18',
    topic: '가치 전달 방식',
    text: '서비스 데모를 진행할 때...',
    options: [
      { id: 'q18o1', text: '고객 업무 시나리오 중심 시연', score: { VALUE: 2 } },
      { id: 'q18o2', text: '고객이 관심 있는 기능 위주 시연', score: { VALUE: 1 } },
      { id: 'q18o3', text: '핵심 가치와 주요 기능 균형 시연', score: { VALUE: 0 } },
      { id: 'q18o4', text: '차별화된 핵심 기능 집중 시연', score: { VALUE: -1 } },
      { id: 'q18o5', text: '전체 서비스를 체계적으로 시연', score: { VALUE: -2 } },
    ],
  },
  {
    id: 'q19',
    topic: '가치 전달 방식',
    text: '고객 사례를 소개할 때...',
    options: [
      { id: 'q19o1', text: '유사한 문제를 해결한 사례 중심', score: { VALUE: 2 } },
      { id: 'q19o2', text: '고객과 비슷한 상황의 성공 사례', score: { VALUE: 1 } },
      { id: 'q19o3', text: '다양한 관점의 활용 사례 제시', score: { VALUE: 0 } },
      { id: 'q19o4', text: '서비스 활용의 모범 사례 소개', score: { VALUE: -1 } },
      { id: 'q19o5', text: '서비스 기능별 활용 사례 설명', score: { VALUE: -2 } },
    ],
  },
  {
    id: 'q20',
    topic: '가치 전달 방식',
    text: '영업 프레젠테이션의 구성은...',
    options: [
      { id: 'q20o1', text: '고객 과제 → 해결 방안 → 서비스 소개', score: { VALUE: 2 } },
      { id: 'q20o2', text: '고객 니즈 → 맞춤 솔루션 → 기대 효과', score: { VALUE: 1 } },
      { id: 'q20o3', text: '시장 동향 → 고객 과제 → 우리 솔루션', score: { VALUE: 0 } },
      { id: 'q20o4', text: '회사 소개 → 서비스 차별점 → 고객 혜택', score: { VALUE: -1 } },
      { id: 'q20o5', text: '서비스 개요 → 상세 기능 → 기술 구성', score: { VALUE: -2 } },
    ],
  },
  {
    id: 'q21',
    topic: '가치 전달 방식',
    text: 'ROI를 설명할 때...',
    options: [
      { id: 'q21o1', text: '고객의 구체적 상황에 기반한 계산', score: { VALUE: 2 } },
      { id: 'q21o2', text: '고객이 중시하는 지표 중심 설명', score: { VALUE: 1 } },
      { id: 'q21o3', text: '정량적 ROI와 정성적 가치 통합', score: { VALUE: 0 } },
      { id: 'q21o4', text: '우리 서비스의 일반적 ROI 수치 제시', score: { VALUE: -1 } },
      { id: 'q21o5', text: '기능별 세부 ROI 분석 자료 제공', score: { VALUE: -2 } },
    ],
  },
  {
    id: 'q22',
    topic: '가치 전달 방식',
    text: '고객이 서비스 이해를 어려워할 때...',
    options: [
      { id: 'q22o1', text: '고객의 언어로 쉽게 재설명', score: { VALUE: 2 } },
      { id: 'q22o2', text: '고객 업무와 연결하여 설명', score: { VALUE: 1 } },
      { id: 'q22o3', text: '단계별로 나누어 차근차근 설명', score: { VALUE: 0 } },
      { id: 'q22o4', text: '핵심 기능만 간단히 재설명', score: { VALUE: -1 } },
      { id: 'q22o5', text: '상세한 매뉴얼과 자료 제공', score: { VALUE: -2 } },
    ],
  },
  {
    id: 'q23',
    topic: '가치 전달 방식',
    text: '영업 성공의 핵심은...',
    options: [
      { id: 'q23o1', text: '고객 문제의 정확한 진단과 처방', score: { VALUE: 2 } },
      { id: 'q23o2', text: '고객 니즈와 솔루션의 완벽한 매칭', score: { VALUE: 1 } },
      { id: 'q23o3', text: '고객 가치와 서비스 특징의 균형', score: { VALUE: 0 } },
      { id: 'q23o4', text: '서비스의 차별화된 가치 전달', score: { VALUE: -1 } },
      { id: 'q23o5', text: '서비스의 우수성에 대한 확신', score: { VALUE: -2 } },
    ],
  },
  {
    id: 'q24',
    topic: '가치 전달 방식',
    text: '이상적인 영업 대화의 비중은...',
    options: [
      { id: 'q24o1', text: '경청 70% : 말하기 30%', score: { VALUE: 2 } },
      { id: 'q24o2', text: '경청 50% : 말하기 50%', score: { VALUE: 1 } },
      { id: 'q24o3', text: '경청 40% : 말하기 60%', score: { VALUE: 0 } },
      { id: 'q24o4', text: '경청 30% : 말하기 70%', score: { VALUE: -1 } },
      { id: 'q24o5', text: '경청 20% : 말하기 80%', score: { VALUE: -2 } },
    ],
  },

  // Axis 3: 관계 구축 방식 (Relationship Building) - E: Emotional ↔ T: Transactional
  {
    id: 'q25',
    topic: '관계 구축 방식',
    text: '첫 미팅 시작 시 주로...',
    options: [
      { id: 'q25o1', text: '개인적 관심사로 자연스럽게 시작', score: { RELATIONSHIP: 2 } },
      { id: 'q25o2', text: '가벼운 안부와 날씨 이야기', score: { RELATIONSHIP: 1 } },
      { id: 'q25o3', text: '간단한 인사 후 본론 진입', score: { RELATIONSHIP: 0 } },
      { id: 'q25o4', text: '미팅 목적과 아젠다 확인', score: { RELATIONSHIP: -1 } },
      { id: 'q25o5', text: '바로 비즈니스 주제로 시작', score: { RELATIONSHIP: -2 } },
    ],
  },
  {
    id: 'q26',
    topic: '관계 구축 방식',
    text: '고객과의 적정 미팅 시간은...',
    options: [
      { id: 'q26o1', text: '충분한 관계 형성 위해 2시간 이상', score: { RELATIONSHIP: 2 } },
      { id: 'q26o2', text: '1시간 30분 정도의 여유로운 미팅', score: { RELATIONSHIP: 1 } },
      { id: 'q26o3', text: '1시간 내외의 균형잡힌 미팅', score: { RELATIONSHIP: 0 } },
      { id: 'q26o4', text: '30-45분의 효율적인 미팅', score: { RELATIONSHIP: -1 } },
      { id: 'q26o5', text: '15-30분의 핵심만 다루는 미팅', score: { RELATIONSHIP: -2 } },
    ],
  },
  {
    id: 'q27',
    topic: '관계 구축 방식',
    text: '고객의 개인적 이야기를 할 때...',
    options: [
      { id: 'q27o1', text: '적극적으로 관심 표현하며 대화 이어감', score: { RELATIONSHIP: 2 } },
      { id: 'q27o2', text: '공감하며 자연스럽게 경청', score: { RELATIONSHIP: 1 } },
      { id: 'q27o3', text: '적절히 반응하며 비즈니스로 전환', score: { RELATIONSHIP: 0 } },
      { id: 'q27o4', text: '간단히 듣고 본론으로 유도', score: { RELATIONSHIP: -1 } },
      { id: 'q27o5', text: '시간 낭비로 생각하고 최소화', score: { RELATIONSHIP: -2 } },
    ],
  },
  {
    id: 'q28',
    topic: '관계 구축 방식',
    text: '미팅 후 팔로우업은...',
    options: [
      { id: 'q28o1', text: '감사 인사와 함께 개인적 안부 포함', score: { RELATIONSHIP: 2 } },
      { id: 'q28o2', text: '미팅 내용 정리와 따뜻한 마무리', score: { RELATIONSHIP: 1 } },
      { id: 'q28o3', text: '핵심 내용 요약과 다음 단계 제안', score: { RELATIONSHIP: 0 } },
      { id: 'q28o4', text: '논의사항 확인과 액션 아이템 전달', score: { RELATIONSHIP: -1 } },
      { id: 'q28o5', text: '필요한 자료만 간단히 전송', score: { RELATIONSHIP: -2 } },
    ],
  },
  {
    id: 'q29',
    topic: '관계 구축 방식',
    text: '고객 생일이나 기념일에...',
    options: [
      { id: 'q29o1', text: '개인적 축하 메시지와 선물 전달', score: { RELATIONSHIP: 2 } },
      { id: 'q29o2', text: '따뜻한 축하 메시지 발송', score: { RELATIONSHIP: 1 } },
      { id: 'q29o3', text: '상황에 따라 축하 인사', score: { RELATIONSHIP: 0 } },
      { id: 'q29o4', text: '업무 관련 대화 시 언급', score: { RELATIONSHIP: -1 } },
      { id: 'q29o5', text: '특별히 챙기지 않음', score: { RELATIONSHIP: -2 } },
    ],
  },
  {
    id: 'q30',
    topic: '관계 구축 방식',
    text: '고객이 개인적 고민을 털어놓을 때...',
    options: [
      { id: 'q30o1', text: '충분한 시간을 갖고 진심으로 경청', score: { RELATIONSHIP: 2 } },
      { id: 'q30o2', text: '공감하며 적절한 조언 제공', score: { RELATIONSHIP: 1 } },
      { id: 'q30o3', text: '간단히 들은 후 비즈니스 주제로', score: { RELATIONSHIP: 0 } },
      { id: 'q30o4', text: '업무 시간 외 따로 시간 제안', score: { RELATIONSHIP: -1 } },
      { id: 'q30o5', text: '사적인 영역이라 최소한만 반응', score: { RELATIONSHIP: -2 } },
    ],
  },
  {
    id: 'q31',
    topic: '관계 구축 방식',
    text: '장기 고객 관계 유지를 위해...',
    options: [
      { id: 'q31o1', text: '정기적 안부 연락과 만남 유지', score: { RELATIONSHIP: 2 } },
      { id: 'q31o2', text: '비즈니스 가치와 개인적 관심 균형', score: { RELATIONSHIP: 1 } },
      { id: 'q31o3', text: '필요시 연락하는 자연스러운 관계', score: { RELATIONSHIP: 0 } },
      { id: 'q31o4', text: '업무적 필요에 따른 정기 연락', score: { RELATIONSHIP: -1 } },
      { id: 'q31o5', text: '계약 기간 중심의 관계 유지', score: { RELATIONSHIP: -2 } },
    ],
  },
  {
    id: 'q32',
    topic: '관계 구축 방식',
    text: '팀 회식이나 친목 모임에서...',
    options: [
      { id: 'q32o1', text: '적극적으로 분위기를 주도하며 즐김', score: { RELATIONSHIP: 2 } },
      { id: 'q32o2', text: '자연스럽게 어울리며 관계 강화', score: { RELATIONSHIP: 1 } },
      { id: 'q32o3', text: '적당히 참여하며 네트워킹', score: { RELATIONSHIP: 0 } },
      { id: 'q32o4', text: '의무적으로 참석 후 일찍 귀가', score: { RELATIONSHIP: -1 } },
      { id: 'q32o5', text: '업무 외 시간은 개인적으로 활용', score: { RELATIONSHIP: -2 } },
    ],
  },
  {
    id: 'q33',
    topic: '관계 구축 방식',
    text: '고객사 직원들과의 관계는...',
    options: [
      { id: 'q33o1', text: '모든 레벨에서 폭넓은 인맥 구축', score: { RELATIONSHIP: 2 } },
      { id: 'q33o2', text: '주요 이해관계자와 깊은 관계', score: { RELATIONSHIP: 1 } },
      { id: 'q33o3', text: '업무 관련자들과 적절한 관계', score: { RELATIONSHIP: 0 } },
      { id: 'q33o4', text: '의사결정자 중심 효율적 관계', score: { RELATIONSHIP: -1 } },
      { id: 'q33o5', text: '핵심 담당자와만 최소한 관계', score: { RELATIONSHIP: -2 } },
    ],
  },
  {
    id: 'q34',
    topic: '관계 구축 방식',
    text: '거절이나 실패 후 고객 관계는...',
    options: [
      { id: 'q34o1', text: '더욱 신경 써서 관계 유지 노력', score: { RELATIONSHIP: 2 } },
      { id: 'q34o2', text: '자연스럽게 연락하며 기회 모색', score: { RELATIONSHIP: 1 } },
      { id: 'q34o3', text: '적절한 거리 두며 관계 유지', score: { RELATIONSHIP: 0 } },
      { id: 'q34o4', text: '필요시에만 업무적 연락', score: { RELATIONSHIP: -1 } },
      { id: 'q34o5', text: '자연스럽게 관계 정리', score: { RELATIONSHIP: -2 } },
    ],
  },
  {
    id: 'q35',
    topic: '관계 구축 방식',
    text: '이상적인 고객 관계는...',
    options: [
      { id: 'q35o1', text: '비즈니스를 넘어선 인간적 신뢰', score: { RELATIONSHIP: 2 } },
      { id: 'q35o2', text: '전문성과 친밀감의 균형', score: { RELATIONSHIP: 1 } },
      { id: 'q35o3', text: '상호 이익 기반의 파트너십', score: { RELATIONSHIP: 0 } },
      { id: 'q35o4', text: '명확한 업무적 신뢰 관계', score: { RELATIONSHIP: -1 } },
      { id: 'q35o5', text: '효율적인 거래 관계', score: { RELATIONSHIP: -2 } },
    ],
  },
  {
    id: 'q36',
    topic: '관계 구축 방식',
    text: 'SNS(소셜미디어)를 통한 고객 관계는...',
    options: [
      { id: 'q36o1', text: '적극적으로 소통하고 일상 공유', score: { RELATIONSHIP: 2 } },
      { id: 'q36o2', text: '적절히 반응하며 관계 유지', score: { RELATIONSHIP: 1 } },
      { id: 'q36o3', text: '비즈니스 콘텐츠 중심 연결', score: { RELATIONSHIP: 0 } },
      { id: 'q36o4', text: '필요시에만 제한적 활용', score: { RELATIONSHIP: -1 } },
      { id: 'q36o5', text: '업무와 개인 영역 철저히 분리', score: { RELATIONSHIP: -2 } },
    ],
  },

  // Axis 4: 의사결정 스타일 (Decision Making) - I: Independent ↔ C: Collaborative
  {
    id: 'q37',
    topic: '의사결정 스타일',
    text: '고객이 즉석에서 할인을 요구할 때...',
    options: [
      { id: 'q37o1', text: '내 권한 내에서 즉시 결정하여 대응', score: { DECISION: 2 } },
      { id: 'q37o2', text: '가이드라인 내에서 유연하게 판단', score: { DECISION: 1 } },
      { id: 'q37o3', text: '중요도에 따라 상사와 상의 여부 결정', score: { DECISION: 0 } },
      { id: 'q37o4', text: '대부분 팀과 논의 후 회신', score: { DECISION: -1 } },
      { id: 'q37o5', text: '반드시 정해진 프로세스 따라 진행', score: { DECISION: -2 } },
    ],
  },
  {
    id: 'q38',
    topic: '의사결정 스타일',
    text: '새로운 영업 전략을 시도할 때...',
    options: [
      { id: 'q38o1', text: '내 판단으로 바로 실행해보고 수정', score: { DECISION: 2 } },
      { id: 'q38o2', text: '기본 방향 내에서 자율적 시도', score: { DECISION: 1 } },
      { id: 'q38o3', text: '팀과 아이디어 공유 후 실행', score: { DECISION: 0 } },
      { id: 'q38o4', text: '상사 승인 받고 팀과 함께 진행', score: { DECISION: -1 } },
      { id: 'q38o5', text: '전사 전략에 맞춰 체계적 실행', score: { DECISION: -2 } },
    ],
  },
  {
    id: 'q39',
    topic: '의사결정 스타일',
    text: '예상치 못한 고객 요구사항에 대해...',
    options: [
      { id: 'q39o1', text: '현장에서 창의적 해결책 즉시 제시', score: { DECISION: 2 } },
      { id: 'q39o2', text: '경험을 바탕으로 빠르게 대안 모색', score: { DECISION: 1 } },
      { id: 'q39o3', text: '일단 검토 후 최선의 방안 회신', score: { DECISION: 0 } },
      { id: 'q39o4', text: '팀과 논의하여 정확한 답변 전달', score: { DECISION: -1 } },
      { id: 'q39o5', text: '회사 정책 확인 후 공식 답변', score: { DECISION: -2 } },
    ],
  },
  {
    id: 'q40',
    topic: '의사결정 스타일',
    text: '영업 목표 설정 시...',
    options: [
      { id: 'q40o1', text: '내가 주도적으로 도전적 목표 설정', score: { DECISION: 2 } },
      { id: 'q40o2', text: '회사 목표보다 높은 개인 목표 추구', score: { DECISION: 1 } },
      { id: 'q40o3', text: '회사 목표와 개인 역량 고려 조정', score: { DECISION: 0 } },
      { id: 'q40o4', text: '팀과 충분히 논의하여 합의', score: { DECISION: -1 } },
      { id: 'q40o5', text: '회사가 정한 목표 충실히 수행', score: { DECISION: -2 } },
    ],
  },
  {
    id: 'q41',
    topic: '의사결정 스타일',
    text: '복잡한 계약 조건 협상 시...',
    options: [
      { id: 'q41o1', text: '내 경험과 판단으로 현장 결정', score: { DECISION: 2 } },
      { id: 'q41o2', text: '핵심 사항은 직접, 세부사항은 확인', score: { DECISION: 1 } },
      { id: 'q41o3', text: '중요도에 따라 결정 권한 구분', score: { DECISION: 0 } },
      { id: 'q41o4', text: '대부분 법무팀과 상의하여 진행', score: { DECISION: -1 } },
      { id: 'q41o5', text: '모든 조항 회사 승인 절차 준수', score: { DECISION: -2 } },
    ],
  },
  {
    id: 'q42',
    topic: '의사결정 스타일',
    text: '실패한 영업 건에 대한 분석은...',
    options: [
      { id: 'q42o1', text: '스스로 원인 분석하고 개선책 도출', score: { DECISION: 2 } },
      { id: 'q42o2', text: '개인 분석 후 선택적으로 공유', score: { DECISION: 1 } },
      { id: 'q42o3', text: '팀과 함께 분석하며 학습', score: { DECISION: 0 } },
      { id: 'q42o4', text: '팀 미팅에서 사례 공유 및 논의', score: { DECISION: -1 } },
      { id: 'q42o5', text: '회사 프로세스에 따라 보고서 작성', score: { DECISION: -2 } },
    ],
  },
  {
    id: 'q43',
    topic: '의사결정 스타일',
    text: '신규 고객 접근 방법 결정 시...',
    options: [
      { id: 'q43o1', text: '내 스타일대로 자유롭게 접근', score: { DECISION: 2 } },
      { id: 'q43o2', text: '기본 틀 안에서 창의적 시도', score: { DECISION: 1 } },
      { id: 'q43o3', text: '검증된 방법과 새로운 시도 병행', score: { DECISION: 0 } },
      { id: 'q43o4', text: '팀의 베스트 프랙티스 활용', score: { DECISION: -1 } },
      { id: 'q43o5', text: '회사 영업 프로세스 준수', score: { DECISION: -2 } },
    ],
  },
  {
    id: 'q44',
    topic: '의사결정 스타일',
    text: '일정 관리와 우선순위 설정은...',
    options: [
      { id: 'q44o1', text: '완전한 내 판단으로 자율 관리', score: { DECISION: 2 } },
      { id: 'q44o2', text: '큰 틀은 회사, 세부는 자율 조정', score: { DECISION: 1 } },
      { id: 'q44o3', text: '팀 일정 고려하며 개인 일정 수립', score: { DECISION: 0 } },
      { id: 'q44o4', text: '팀과 긴밀히 조율하여 관리', score: { DECISION: -1 } },
      { id: 'q44o5', text: '회사 시스템에 따라 체계적 관리', score: { DECISION: -2 } },
    ],
  },
  {
    id: 'q45',
    topic: '의사결정 스타일',
    text: '고객 클레임 발생 시...',
    options: [
      { id: 'q45o1', text: '즉시 내 판단으로 해결책 실행', score: { DECISION: 2 } },
      { id: 'q45o2', text: '상황 판단 후 빠른 초기 대응', score: { DECISION: 1 } },
      { id: 'q45o3', text: '심각도에 따라 대응 수준 결정', score: { DECISION: 0 } },
      { id: 'q45o4', text: '팀과 상의하여 종합적 대응', score: { DECISION: -1 } },
      { id: 'q45o5', text: '클레임 처리 프로세스 엄격 준수', score: { DECISION: -2 } },
    ],
  },
  {
    id: 'q46',
    topic: '의사결정 스타일',
    text: '영업 도구나 시스템 활용은...',
    options: [
      { id: 'q46o1', text: '내게 맞는 방식으로 자유롭게 활용', score: { DECISION: 2 } },
      { id: 'q46o2', text: '기본 기능 위주로 효율적 활용', score: { DECISION: 1 } },
      { id: 'q46o3', text: '필요에 따라 선택적 활용', score: { DECISION: 0 } },
      { id: 'q46o4', text: '팀이 합의한 방식으로 활용', score: { DECISION: -1 } },
      { id: 'q46o5', text: '회사 규정대로 빠짐없이 활용', score: { DECISION: -2 } },
    ],
  },
  {
    id: 'q47',
    topic: '의사결정 스타일',
    text: '성과 보상이나 인센티브에 대해...',
    options: [
      { id: 'q47o1', text: '개인 성과에 따른 차등 보상 선호', score: { DECISION: 2 } },
      { id: 'q47o2', text: '개인 성과 중심, 팀 성과 일부 반영', score: { DECISION: 1 } },
      { id: 'q47o3', text: '개인과 팀 성과 균형있게 반영', score: { DECISION: 0 } },
      { id: 'q47o4', text: '팀 성과 중심, 개인 기여도 반영', score: { DECISION: -1 } },
      { id: 'q47o5', text: '조직 전체 성과에 따른 배분 선호', score: { DECISION: -2 } },
    ],
  },
  {
    id: 'q48',
    topic: '의사결정 스타일',
    text: '나의 이상적인 업무 환경은...',
    options: [
      { id: 'q48o1', text: '완전한 자율성과 독립성 보장', score: { DECISION: 2 } },
      { id: 'q48o2', text: '방향성 제시 후 자율적 실행', score: { DECISION: 1 } },
      { id: 'q48o3', text: '자율과 협업의 적절한 균형', score: { DECISION: 0 } },
      { id: 'q48o4', text: '팀워크 중심의 협업 환경', score: { DECISION: -1 } },
      { id: 'q48o5', text: '명확한 역할과 프로세스 정립', score: { DECISION: -2 } },
    ],
  },
];

const mbtiResultsData = {
  PSEC: {
    name: '사자 🦁 "정글의 왕, 모두를 이끄는 리더"',
    coreCharacteristics: ['카리스마', '도전정신', '리더십'],
    salesStyle: ['주도적 대화', '비전 중심 제안', '대형 프레젠테이션 선호'],
    고객이바라보는당신의모습: '강렬한 존재감과 카리스마로 공간을 장악합니다. 완벽한 외모와 말투, 자신감 있는 태도는 고객에게 강한 인상을 남깁니다.',
    고객이느끼는당신의성향: '책임감 있고 방향성을 제시하는 리더로 인식됩니다. 목표 지향적이나 다소 일방적으로 느껴질 수 있습니다.',
    고객이경험하는영업스타일: '프레임을 설정하고, 주도적으로 대화를 이끕니다. 고객의 비전을 설계하며 큰 그림 중심으로 접근합니다.',
    강점: [
      '추진력과 영향력으로 신뢰 형성',
      '큰 계약이나 전략적 파트너십에 적합',
    ],
    약점: [
      '고객의 세부 니즈나 맥락을 간과할 위험',
      '상대의 발언 기회를 줄이는 스타일로 오해 가능',
    ],
    고객과의궁합: {
      good: ['궁합 좋음: 빠른 의사결정을 선호하는 경영자형 고객'],
      bad: ['궁합 주의: 관계 중심, 공감형 고객'],
    },
    추천교육: {
      교육명: '[세일즈 리더십 3S 솔루션]',
      교육포인트: '전략적 리더십 강화, 조직 성과관리, 팀 코칭 능력 향상',
      교육방향: '이 과정은 사자의 리더십과 전략 능력을 더욱 확장해 팀 전체의 시너지를 이끌어내는 강점 강화형 교육입니다.',
      인사이트: '"영업은 단순한 거래가 아니라 함께 미래를 그려가는 것"',
    },
    illustration: 'https://placehold.co/150x150/FFD700/000000?text=PSEC+🦁',
  },
  PSEI: {
    name: '독수리 🦅 "하늘을 지배하는 고독한 사냥꾼"',
    coreCharacteristics: ['자기주도', '집중력', '빠른 실행'],
    salesStyle: ['철저한 준비', '핵심 파악', '단독 고성과'],
    고객이바라보는당신의모습: '날카로운 눈매와 강인한 인상, 미니멀한 스타일의 정장. 불필요한 장식은 배제하고 기능성을 중시하는 차림새.',
    고객이느끼는당신의성향: '독립적이고 자기주도적이며 목표 지향적입니다. 감정 표현은 절제하나 내면은 열정적입니다. 혼자 일하는 것을 선호합니다.',
    고객이경험하는영업스타일: '철저한 사전 조사와 준비를 바탕으로 일대일 미팅에서 최고의 성과를 냅니다. 고객 니즈의 핵심을 정확히 파악하고 빠른 의사결정과 실행을 유도합니다.',
    강점: [
      '높은 성사율',
      '효율적인 시간 관리',
      '독자적인 문제 해결 능력',
    ],
    약점: [
      '팀워크 부족',
      '정보 공유 미흡',
      '유연성 부족',
    ],
    고객과의궁합: {
      good: ['✅ 바쁜 의사결정자, 효율성 중시 고객'],
      bad: ['❌ 관계 중시, 장기적 파트너십 추구 고객'],
    },
    추천교육: {
      교육명: '[ChatGPT 상담스킬 연습]',
      교육포인트: '개인 맞춤 Role-play 훈련, 사전 시뮬레이션 역량 강화',
      교육방향: '독수리형의 철저한 사전 준비와 단독 수행력을 더욱 정밀하게 훈련하는 강점 증폭형 코스입니다.',
      인사이트: '"목표를 향한 집중력이 곧 성공의 열쇠"',
    },
    illustration: 'https://placehold.co/150x150/87CEEB/000000?text=PSEI+🦅',
  },
  PSTC: {
    name: '늑대 🐺 "무리와 함께 달리는 전략가"',
    coreCharacteristics: ['팀 중심', '전략적 사고', '체계적 접근'],
    salesStyle: ['팀 기반 어프로치', '장기관계 중심'],
    고객이바라보는당신의모습: '깔끔하면서도 팀 색상이 드러나는 액세서리 착용. 동료들과 어울리면서도 자신만의 개성을 잃지 않는 스타일.',
    고객이느끼는당신의성향: '팀 플레이어이면서 전략적 사고를 하며, 충성심 강하고 신뢰할 수 있습니다. 체계적이고 계획적이며 목표 달성을 위해 협력 중시합니다.',
    고객이경험하는영업스타일: '팀 단위 어프로치를 선호하며 체계적인 계정 관리를 통해 장기적 관계 구축에 집중합니다. 내부 협업을 통한 최적 솔루션 제공을 강조합니다.',
    강점: [
      '복잡한 딜 관리 능력',
      '팀 시너지 창출',
      '지속 가능한 성과',
    ],
    약점: [
      '개인 판단 주저',
      '의사결정 속도 느림',
      '관료적 접근 가능성',
    ],
    고객과의궁합: {
      good: ['✅ 조직 구매, 복잡한 의사결정 구조'],
      bad: ['❌ 빠른 결정 필요, 개인 사업자'],
    },
    추천교육: {
      교육명: '[Win-Win 세일즈 협상]',
      교육포인트: '협상 계획 수립, 협상 대안 개발, 실전 협업 능력 강화',
      교육방향: '늑대형의 강점인 팀 기반 전략 접근을 실전 협상으로 연결하는 시너지 확대형 교육입니다.',
      인사이트: '"혼자 가면 빨리 가지만, 함께 가면 멀리 간다"',
    },
    illustration: 'https://placehold.co/150x150/778899/ffffff?text=PSTC+🐺',
  },
  PSTI: {
    name: '표범 🐆 "은밀하게 목표를 추격하는 스프린터"',
    coreCharacteristics: ['민첩성', '실행력', '효율성'],
    salesStyle: ['간결하고 빠른 클로징', '타이밍 중심'],
    고객이바라보는당신의모습: '슬림한 실루엣의 다크 톤 정장, 민첩한 움직임. 눈에 띄지 않으면서도 프로페셔널한 인상.',
    고객이느끼는당신의성향: '신속하고 과감한 실행력을 가지며 기회 포착에 뛰어납니다. 결과 중심적 사고와 효율성 극대화를 추구합니다.',
    고객이경험하는영업스타일: '빠른 접근과 신속한 클로징을 통해 타이밍을 중시하는 영업을 합니다. 핵심만 간결하게 전달하고 불필요한 과정을 최소화합니다.',
    강점: [
      '단기 성과 창출',
      '기회 비용 최소화',
      '민첩한 대응',
    ],
    약점: [
      '장기적 관계 소홀',
      '섬세함 부족',
      '팀 협업 어려움',
    ],
    고객과의궁합: {
      good: ['✅ 신속한 의사결정자, 실무 담당자'],
      bad: ['❌ 신중한 검토자, 관계 중시 고객'],
    },
    추천교육: {
      교육명: '[폰서비스 Skill-Up]',
      교육포인트: '전화/고객 응대 신속성, 초기 인상 강화',
      교육방향: '표범형의 강점인 속도와 임팩트를 실전 콜 응대 역량으로 연결하여 즉시성과를 높이는 강화형 과정입니다.',
      인사이트: '"기회는 준비된 자에게만 보인다"',
    },
    illustration: 'https://placehold.co/150x150/36454F/ffffff?text=PSTI+🐆',
  },
  PFEC: {
    name: '코끼리 🐘 "거대한 지혜로 길을 여는 개척자"',
    coreCharacteristics: ['인내', '신뢰', '해박한 지식'],
    salesStyle: ['교육적 설명', '꾸준한 팔로우업'],
    고객이바라보는당신의모습: '든든한 체구에 온화한 미소, 클래식한 스타일. 신뢰감을 주는 차분한 색상의 정장과 품격 있는 액세서리.',
    고객이느끼는당신의성향: '인내심 강하고 꾸준하며 서비스 지식이 해박합니다. 팀과 고객 모두를 배려하며 장기적 시각을 보유합니다.',
    고객이경험하는영업스타일: '서비스의 가치를 충분히 설명하고 교육적 접근 방식을 선호합니다. 고객과 함께 성장하는 파트너십을 구축하며 꾸준한 팔로우업을 통해 신뢰를 쌓습니다.',
    강점: [
      '깊이 있는 컨설팅',
      '신뢰 관계 구축',
      '복잡한 서비스 설명 능력',
    ],
    약점: [
      '느린 진행 속도',
      '과도한 정보 제공',
      '클로징 시점 놓침',
    ],
    고객과의궁합: {
      good: ['✅ 기술 중심 기업, 장기 프로젝트'],
      bad: ['❌ 빠른 ROI 추구, 단순 거래 선호'],
    },
    추천교육: {
      교육명: '[불만고객응대]',
      교육포인트: '감정 대응, 고객신뢰 확보, 현장 사례 기반 실습',
      교육방향: '코끼리형의 지식 중심 접근에 감정관리 스킬을 보완하여 고객 신뢰를 극대화하는 약점 보완형 교육입니다.',
      인사이트: '"깊이 있는 이해가 진정한 가치를 만든다"',
    },
    illustration: 'https://placehold.co/150x150/6B8E23/ffffff?text=PFEC+🐘',
  },
  PFEI: {
    name: '호랑이 🐅 "홀로 영역을 지키는 강력한 수호자"',
    coreCharacteristics: ['자부심', '전문성', '품질중심'],
    salesStyle: ['프리미엄 포지셔닝', '선택적 고객 응대'],
    고객이바라보는당신의모습: '강렬한 인상의 파워 드레싱, 완벽한 그루밍. 고급스러운 소재와 대담한 컬러 포인트.',
    고객이느끼는당신의성향: '강한 자부심과 전문성을 가지며 독립적이고 자신감 넘칩니다. 서비스에 대한 확고한 신념과 타협하지 않는 품질을 추구합니다.',
    고객이경험하는영업스타일: '서비스의 우수성을 강조하고 프리미엄 포지셔닝을 통해 독점적 가치를 제안합니다. 선택된 고객만 상대하며 품질에 대한 확고한 신념을 보여줍니다.',
    강점: [
      '높은 마진 거래',
      '브랜드 가치 구축',
      '전문가적 권위',
    ],
    약점: [
      '유연성 부족',
      '시장 변화 대응 늦음',
      '고객층 제한적',
    ],
    고객과의궁합: {
      good: ['✅ 품질 우선 고객, 프리미엄 시장'],
      bad: ['❌ 가격 민감 고객, 대량 구매자'],
    },
    추천교육: {
      교육명: '[The Service Difference]',
      교육포인트: '고품질 서비스 응대, 충성고객 전략',
      교육방향: '호랑이형의 고품질 지향을 고객 경험 설계로 연결해 고가치 고객을 강화하는 강점 확대형 교육입니다.',
      인사이트: '"최고가 되려면 최고만을 추구하라"',
    },
    illustration: 'https://placehold.co/150x150/FF8C00/ffffff?text=PFEI+🐅',
  },
  PFTC: {
    name: '개미 🐜 "체계적으로 제국을 건설하는 일꾼"',
    coreCharacteristics: ['근면성', '조직성', '프로세스 중심'],
    salesStyle: ['데이터 기반', '정확한 문서화'],
    고객이바라보는당신의모습: '깔끔하고 실용적인 비즈니스 캐주얼, 효율적인 움직임. 항상 태블릿과 체크리스트를 소지.',
    고객이느끼는당신의성향: '극도로 체계적이고 조직적이며 근면 성실하고 책임감 강합니다. 프로세스와 시스템을 중시하며 팀의 일원으로서 자부심을 가집니다.',
    고객이경험하는영업스타일: '데이터 기반 접근과 체계적인 파이프라인 관리를 통해 안정적인 성과를 추구합니다. 정확한 문서화와 보고, 팀 프로세스 준수를 강조합니다.',
    강점: [
      '안정적인 성과',
      '리스크 최소화',
      '확장 가능한 영업 모델',
    ],
    약점: [
      '창의성 부족',
      '예외 상황 대응 미흡',
      '과도한 프로세스 의존',
    ],
    고객과의궁합: {
      good: ['✅ 대기업, 체계적 구매 프로세스'],
      bad: ['❌ 스타트업, 유연한 대응 필요'],
    },
    추천교육: {
      교육명: '[빅데이터 영업전략 수립]',
      교육포인트: '전략적 데이터 활용, 구조적 분석 훈련',
      교육방향: '개미형의 체계성과 데이터 기반 업무방식을 확장하여 예측가능한 성과를 만드는 강점 강화형 교육입니다.',
      인사이트: '"작은 노력의 축적이 위대한 성과를 만든다"',
    },
    illustration: 'https://placehold.co/150x150/B0E0E6/000000?text=PFTC+🐜',
  },
  PFTI: {
    name: '매 🦅 "정확한 타격으로 사냥하는 저격수"',
    coreCharacteristics: ['집중력', '효율성', '분석력'],
    salesStyle: ['ROI 중심', '타겟팅 명확'],
    고객이바라보는당신의모습: '샤프한 인상의 미니멀 스타일, 기능적이면서도 세련된 착장. 불필요한 것은 모두 제거한 심플함.',
    고객이느끼는당신의성향: '극도의 집중력과 정확성을 가지며 효율성을 최우선 가치로 둡니다. 감정보다 논리와 데이터를 중시하며 목표 외 모든 것은 부차적입니다.',
    고객이경험하는영업스타일: '타겟팅된 고객에게만 접근하여 핵심 기능과 ROI 중심의 설명을 제공합니다. 짧고 임팩트 있는 프레젠테이션으로 즉각적인 의사결정을 유도합니다.',
    강점: [
      '높은 투자 대비 성과',
      '시간 효율성',
      '명확한 가치 전달',
    ],
    약점: [
      '관계 구축 소홀',
      '유연성 부족',
      '좁은 시장 커버리지',
    ],
    고객과의궁합: {
      good: ['✅ 바쁜 경영진, ROI 중시 고객'],
      bad: ['❌ 관계 중시, 감성적 구매자'],
    },
    추천교육: {
      교육명: '[CX 디자인씽킹]',
      교육포인트: '고객 중심 솔루션 기획, 핵심 가치 전달',
      교육방향: '매형의 빠르고 정확한 실행력에 공감 기반 고객 접근법을 더하는 약점 보완형 교육입니다.',
      인사이트: '"정확한 한 발이 백 발의 허공을 이긴다"',
    },
    illustration: 'https://placehold.co/150x150/4682B4/ffffff?text=PFTI+🦅',
  },
  RSEC: {
    name: '돌고래 🐬 "파도를 타며 소통하는 메신저"',
    coreCharacteristics: ['친화력', '공감능력', '커뮤니케이션'],
    salesStyle: ['공감 기반 상담', '재구매 유도'],
    고객이바라보는당신의모습: '밝고 친근한 인상, 컬러풀한 액세서리. 항상 미소를 띠고 있으며 열린 자세의 바디랭귀지.',
    고객이느끼는당신의성향: '긍정적이고 친화력이 높으며 뛰어난 커뮤니케이션 능력을 가집니다. 팀워크와 협력을 중시하며 고객의 감정에 공감합니다.',
    고객이경험하는영업스타일: '인바운드 리드 최적화에 강하며 고객과의 래포 형성을 중시합니다. 경청과 공감 기반의 상담을 통해 팀과 활발히 정보 공유하며 고객 만족도를 높입니다.',
    강점: [
      '높은 고객 만족도',
      '추천 및 재구매율 높음',
      '팀 분위기 메이커',
    ],
    약점: [
      '공격적 영업 부족',
      '클로징 주저',
      '숫자 관리 소홀',
    ],
    고객과의궁합: {
      good: ['✅ 장기 파트너십, B2B2C 비즈니스'],
      bad: ['❌ 단기 성과 추구, 가격 협상 중심'],
    },
    추천교육: {
      교육명: '[회복탄력성: 마음근육 키우기]',
      교육포인트: '감정 회복력, 자기긍정감, 관계 유지 역량',
      교육방향: '돌고래형의 감성 커뮤니케이션에 자기회복력과 업무 지속성을 더해주는 약점 보완형 교육입니다.',
      인사이트: '"진정한 소통이 최고의 영업 전략이다"',
    },
    illustration: 'https://placehold.co/150x150/87CEFA/000000?text=RSEC+🐬',
  },
  RSEI: {
    name: '여우 🦊 "영리하게 기회를 포착하는 현자"',
    coreCharacteristics: ['유연성', '전략적 사고', '적응력'],
    salesStyle: ['맞춤형 제안', '전략 조정 유연'],
    고객이바라보는당신의모습: '영리해 보이는 눈빛, 상황에 맞게 변화하는 스타일. 디테일에 신경 쓴 액세서리로 센스를 표현.',
    고객이느끼는당신의성향: '상황 판단력이 뛰어나고 적응력과 유연성을 가집니다. 전략적이고 기회주의적이며 독립적이면서도 영리합니다.',
    고객이경험하는영업스타일: '고객 니즈를 빠르게 파악하고 맞춤형 솔루션을 제안합니다. 상황에 따른 전략 변경에 능숙하며 크로스셀링, 업셀링을 능숙하게 활용합니다.',
    강점: [
      '기회 발견 능력',
      '다양한 고객 대응',
      '창의적 문제 해결',
    ],
    약점: [
      '일관성 부족 가능',
      '신뢰 구축 시간 필요',
      '팀 플레이 약함',
    ],
    고객과의궁합: {
      good: ['✅ 복잡한 니즈, 맞춤형 솔루션 필요'],
      bad: ['❌ 표준화된 프로세스, 투명성 중시'],
    },
    추천교육: {
      교육명: '[고객경험관리]',
      교육포인트: '고객 관점 전환, 여정 기반 응대전략 설계',
      교육방향: '여우형의 상황판단력과 유연성을 고객 관점 전략으로 체계화하는 강점 강화형 교육입니다.',
      인사이트: '"변화하는 시장에서 적응력이 생존력이다"',
    },
    illustration: 'https://placehold.co/150x150/FFC0CB/000000?text=RSEI+🦊',
  },
  RSTC: {
    name: '펭귄 🐧 "혹독한 환경에서도 함께하는 동료"',
    coreCharacteristics: ['안정성', '팀워크', '충성심'],
    salesStyle: ['체계적 인바운드', '일관된 서비스'],
    고객이바라보는당신의모습: '단정한 포멀 스타일, 팀 뱃지나 로고 착용. 프로페셔널하면서도 소속감을 드러내는 차림새.',
    고객이느끼는당신의성향: '충성심과 팀 정신을 가지며 꾸준하고 신뢰할 수 있습니다. 프로세스와 규칙을 준수하며 어려운 상황에서도 긍정적입니다.',
    고객이경험하는영업스타일: '팀 중심의 고객 응대와 체계적인 인바운드 처리를 통해 일관된 서비스 품질을 제공합니다. 장기적 고객 관리에 강하며 안정적인 성과를 추구합니다.',
    강점: [
      '안정적 성과',
      '팀 협업 우수',
      '위기 대응력',
    ],
    약점: [
      '혁신성 부족',
      '개인 역량 발휘 제한',
      '변화 적응 느림',
    ],
    고객과의궁합: {
      good: ['✅ 안정성 중시, 장기 계약 선호'],
      bad: ['❌ 혁신적 솔루션, 빠른 변화 요구'],
    },
    추천교육: {
      교육명: '[불만고객응대]',
      교육포인트: '위기 대응, CS 품질 표준화',
      교육방향: '펭귄형의 충실한 서비스 기반을 고객 감정관리 역량으로 넓혀주는 약점 보완형 교육입니다.',
      인사이트: '"함께 견디면 불가능도 가능해진다"',
    },
    illustration: 'https://placehold.co/150x150/ADD8E6/000000?text=RSTC+🐧',
  },
  RSTI: {
    name: '고양이 🐱 "우아하게 선택하는 독립적인 귀족"',
    coreCharacteristics: ['독립성', '고품질 선호', '기준 명확'],
    salesStyle: ['선별적 고객 응대', '품질 중심'],
    고객이바라보는당신의모습: '세련되고 자신감 있는 태도로 자신만의 기준이 뚜렷한 전문가처럼 보입니다.',
    고객이느끼는당신의성향: '고급스러움과 독립성을 가진 판단 중심형입니다. 선택적 관계 중심으로 거리감 느껴질 수 있습니다.',
    고객이경험하는영업스타일: '개인화된 응대와 고급 정보를 제공합니다. 감정 표현은 제한적이지만 정제된 커뮤니케이션을 합니다.',
    강점: [
      '프리미엄 시장에서의 신뢰 확보',
      '고품질 중심 고객과의 관계 유지',
    ],
    약점: [
      '팀워크와 융통성 약함',
      '일부 고객에게는 폐쇄적 인상',
    ],
    고객과의궁합: {
      good: ['궁합 좋음: 고관여 B2B 고객, VIP 시장'],
      bad: ['궁합 주의: 대량 유통 중심, 협업 중심 구매자'],
    },
    추천교육: {
      교육명: '[고객경험관리 과정]',
      교육포인트: '고객 개별화 중심의 접근에 전략적 CX 설계를 더합니다.',
      교육방향: '고객별 여정 설계 기반 응대, 품질을 넘은 고객 감동 요소 발굴 훈련',
      인사이트: '"선택과 집중이 프리미엄을 만든다"',
    },
    illustration: 'https://placehold.co/150x150/D3D3D3/000000?text=RSTI+🐱',
  },
  RFEC: {
    name: '곰 🐻 "든든한 믿음을 주는 수호신"',
    coreCharacteristics: ['포용력', '안정감', '고객 보호본능'],
    salesStyle: ['지속적 사후관리', '신뢰 중심'],
    고객이바라보는당신의모습: '포근하고 따뜻한 말투로 언제든 의지할 수 있는 상담자처럼 느껴집니다.',
    고객이느끼는당신의성향: '인내심 있고 안정감 있는 모습입니다. 위기나 불만 상황에서도 감정을 받아주는 태도를 보입니다.',
    고객이경험하는영업스타일: '고객의 입장에서 문제를 바라보는 태도를 보입니다. 서비스보다 관계와 신뢰에 초점을 맞춥니다.',
    강점: [
      '충성고객 확보',
      '불만 상황의 긍정적 전환 유도',
    ],
    약점: [
      '공격적 클로징 부족',
      '신규개척보다는 유지 중심',
    ],
    고객과의궁합: {
      good: ['궁합 좋음: 리스크 회피, 장기 계약 지향 고객'],
      bad: ['궁합 주의: ROI 중심 단기 성과 기대 고객'],
    },
    추천교육: {
      교육명: '[불만고객 응대 과정]',
      교육포인트: '신뢰 기반 대응에 불만 대응 전문성까지 더합니다.',
      교육방향: '감정 대응 로직화 및 회복 시나리오 설계, 반복 고객 이슈에서의 진정성 전달법',
      인사이트: '"신뢰는 가장 강력한 영업 도구다"',
    },
    illustration: 'https://placehold.co/150x150/A0522D/ffffff?text=RFEC+🐻',
  },
  RFEI: {
    name: '부엉이 🦉 "밤을 밝히는 지혜로운 조언자"',
    coreCharacteristics: ['통찰력', '분석력', '컨설팅 기질'],
    salesStyle: ['데이터 기반 제안', '교육적 설명'],
    고객이바라보는당신의모습: '이해와 분석에 기반한 조언자로, 차분한 설명과 논리적 전개로 안정감을 줍니다.',
    고객이느끼는당신의성향: '전략과 구조를 중시하는 신뢰 기반 전문가입니다. 즉흥적 대응보다 준비된 조언을 선호합니다.',
    고객이경험하는영업스타일: '리서치 기반 컨설팅 제안을 합니다. 장기적 시각의 전략적 거래를 설계합니다.',
    강점: [
      '복잡한 서비스 상품 구조화 능력',
      '높은 논리적 설득력',
    ],
    약점: [
      '속도감 부족',
      '관계적 유연성은 다소 약함',
    ],
    고객과의궁합: {
      good: ['궁합 좋음: 전략적 의사결정자, 장기 투자 기업'],
      bad: ['궁합 주의: 속도감 중심 B2B 시장'],
    },
    추천교육: {
      교육명: '[빅데이터 기반 영업전략 수립 과정]',
      교육포인트: '구조적 설득 전략에 데이터 기반 논리를 더합니다.',
      교육방향: '고객 구매 논리 기반 프레임 설계, 데이터 기반 신뢰 형성 및 가치 제시',
      인사이트: '"지혜로운 조언이 최고의 가치다"',
    },
    illustration: 'https://placehold.co/150x150/808000/ffffff?text=RFEI+🦉',
  },
  RFTC: {
    name: '비버 🦫 "협력으로 댐을 쌓는 건축가"',
    coreCharacteristics: ['협력', '실용성', '공동구축'],
    salesStyle: ['공동 개발 접근', '단계별 제안'],
    고객이바라보는당신의모습: '실용적이면서 끈기 있는 협업자 이미지로 고객과 함께 솔루션을 만들어가는 인상을 줍니다.',
    고객이느끼는당신의성향: '협업과 현실성에 강한 실용형 사고를 합니다. 장기적 실행력은 강하나 창의성은 다소 제한적입니다.',
    고객이경험하는영업스타일: '단계별 제안서와 실행안을 제공합니다. 고객과 함께 결과를 만드는 프로세스 중심의 영업을 합니다.',
    강점: [
      '고객의 참여도 높이는 영업',
      '고객 맞춤 솔루션 운영에 강함',
    ],
    약점: [
      '속도감 부족',
      '반복적 커스터마이징 부담',
    ],
    고객과의궁합: {
      good: ['궁합 좋음: 맞춤형 프로젝트 고객'],
      bad: ['궁합 주의: 빠른 솔루션 도입 원하는 고객'],
    },
    추천교육: {
      교육명: '[CX 디자인씽킹 과정]',
      교육포인트: '실용적 협업 영업에 창의적 문제 해결 능력을 더합니다.',
      교육방향: '고객 참여형 아이디어 도출 방법론 학습, 실행력 기반 프로토타이핑 스킬 훈련',
      인사이트: '"함께 만들어가는 것이 진정한 파트너십"',
    },
    illustration: 'https://placehold.co/150x150/CD853F/ffffff?text=RFTC+🦫',
  },
  RFTI: {
    name: '거미 🕷️ "정교한 그물을 짜는 설계자"',
    coreCharacteristics: ['체계성', '정밀성', '자동화 활용'],
    salesStyle: ['정교한 프로세스', '시스템 중심 제안'],
    고객이바라보는당신의모습: '정교하고 데이터 중심적인 태도로 체계화된 고객 관리 능력을 가진 전문가로 인식됩니다.',
    고객이느끼는당신의성향: '반복적 구조화에 강하고 예측 가능성이 높습니다. 감정 표현은 적으나 분석 기반의 안정감을 제공합니다.',
    고객이경험하는영업스타일: '자동화 기반 파이프라인을 제시합니다. CRM/데이터 기반 고객 행동 예측을 통해 효율적인 영업을 합니다.',
    강점: [
      '복잡한 고객 흐름 체계화',
      '확장 가능한 영업 구조 설계',
    ],
    약점: [
      '감성적 설득력 부족',
      '고객 상황 급변 시 대응 어려움',
    ],
    추천교육: {
      교육명: '[Service Difference 영업력 과정]',
      교육포인트: '데이터 기반 고객 분석 능력에 감성 설득력과 고객 여정 이해를 더합니다.',
      교육방향: '고객 세그먼트별 가치 커뮤니케이션 훈련, 정량 기반 영업 구조에 맞춤형 감정 요소 접목',
      인사이트: '"완벽한 시스템이 지속가능한 성공을 만든다"',
    },
    illustration: 'https://placehold.co/150x150/4B0082/ffffff?text=RFTI+🕷️',
  },
};


// Firebase configuration and initialization
const appId = typeof __app_id !== 'undefined' ? __app_id : 'default-app-id';
const firebaseConfig = typeof __firebase_config !== 'undefined' ? JSON.parse(__firebase_config) : {};

let app;
let dbInstance;
let authInstance;

if (Object.keys(firebaseConfig).length > 0) {
  try {
    app = initializeApp(firebaseConfig);
    dbInstance = getFirestore(app);
    authInstance = getAuth(app);
  } catch (error) {
    console.error("Firebase initialization error:", error);
  }
} else {
  console.warn("Firebase config not provided. Running in mock mode for persistence.");
}

// Helper component for individual score bars
const ScoreBar = ({ label, score, maxScore }) => {
  const normalizedScore = (score / maxScore) * 100;
  const barWidth = Math.abs(normalizedScore / 2);
  const isPositive = score >= 0;

  const getStrengthLevel = (s) => {
    const absScore = Math.abs(s);
    if (absScore >= 20) return '매우 강함';
    if (absScore >= 12) return '강함';
    if (absScore >= 6) return '보통';
    if (absScore >= 1) return '약함';
    return '중립';
  };

  const strengthLevel = getStrengthLevel(score);
  const strengthColor = isPositive ? 'text-blue-600' : 'text-red-600';

  let mainLabelText = '';
  let leftLabelText = '';
  let rightLabelText = '';

  if (typeof label === 'string') {
    mainLabelText = label.split('(')[0].trim();
    const labelPartsMatch = label.match(/\(([^)]+)\)/);
    if (labelPartsMatch && labelPartsMatch[1]) {
      const rawContent = String(labelPartsMatch[1]);
      const parts = rawContent.split(' ↔ ');
      if (parts.length === 2) {
        leftLabelText = parts[0].trim();
        rightLabelText = parts[1].trim();
      }
    }
  } else {
    mainLabelText = String(label);
    console.error("ScoreBar received non-string label:", label);
  }

  return (
    <div className="mb-4">
      <div className="flex justify-between items-center mb-1">
        <span className="font-semibold text-gray-700">{mainLabelText}</span>
        <span className={`text-sm font-medium ${strengthColor}`}>{strengthLevel} ({score}점)</span>
      </div>
      <div className="relative w-full h-4 bg-gray-200 rounded-full overflow-hidden">
        <div className="absolute left-1/2 top-0 h-full w-0.5 bg-gray-400"></div> {/* Center line */}
        <div
          className={`absolute h-full rounded-full transition-all duration-500 ease-out
            ${isPositive ? 'bg-blue-500' : 'bg-red-500'}
          `}
          style={{
            width: `${barWidth}%`,
            left: isPositive ? '50%' : `${50 - barWidth}%`,
          }}
        ></div>
      </div>
      <div className="flex justify-between text-xs text-gray-600 mt-1">
        <span className="text-red-600 font-medium">{String(leftLabelText)}</span>
        <span className="text-blue-600 font-medium">{String(rightLabelText)}</span>
      </div>
    </div>
  );
};


// Question Page Component
const QuestionPage = ({ question, questionIndex, totalQuestions, onAnswer, onPrev, selectedOptionId }) => {
  const progress = ((questionIndex + 1) / totalQuestions) * 100;

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50 p-4 sm:p-6 md:p-8">
      <div className="w-full max-w-md bg-white rounded-2xl shadow-xl p-6 sm:p-8 flex flex-col justify-between min-h-[500px]">
        <div>
          {/* Progress Bar */}
          <div className="w-full bg-gray-200 rounded-full h-2.5 mb-6 overflow-hidden">
            <div
              className="bg-blue-500 h-2.5 rounded-full transition-all duration-500 ease-out"
              style={{ width: `${progress}%`} }
            ></div>
          </div>

          {/* Question Counter */}
          <p className="text-sm text-gray-500 mb-4 text-center">
            {questionIndex + 1} / {totalQuestions}
          </p>

          {/* Question Text */}
          <h2 className="text-xl sm:text-2xl font-semibold text-gray-800 mb-6 text-center leading-relaxed">
            {question.text}
          </h2>
        </div>

        {/* Options */}
        <div className="flex flex-col space-y-4 flex-grow justify-center">
          {question.options.map((option) => (
            <button
              key={option.id}
              onClick={() => onAnswer(question.id, option.id, option.score)}
              className={`
                w-full py-3 px-4 rounded-xl text-lg text-left transition-all duration-200 ease-in-out
                border-2
                ${selectedOptionId === option.id
                  ? 'bg-blue-500 border-blue-500 text-white shadow-md'
                  : 'bg-white border-gray-300 text-gray-700 hover:bg-blue-50 hover:border-blue-400 hover:text-blue-700'
                }
                focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50
              `}
            >
              {option.text}
            </button>
          ))}
        </div>

        <div>
          {/* Previous Button */}
          <div className="flex justify-center mt-8">
            <button
              onClick={onPrev}
              disabled={questionIndex === 0}
              className={`
                p-3 rounded-full text-gray-500 hover:bg-gray-200 active:bg-gray-300
                ${questionIndex === 0 ? 'opacity-50 cursor-not-allowed' : ''}
              `}
              aria-label="이전 질문"
            >
              <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2">
                <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

// Result Page Component
const ResultPage = ({ resultType, mbtiResultsData, onRestart, userId, axisScores }) => {
  const result = mbtiResultsData[resultType] || {};
  const maxAxisScore = 24; // Max possible score for each axis (12 questions * 2 points)

  const [salesTips, setSalesTips] = useState('');
  const [isGeneratingTips, setIsGeneratingTips] = useState(false);
  const [showTipsModal, setShowTipsModal] = useState(false);
  const [showShareModal, setShowShareModal] = useState(false);
  const [isCopied, setIsCopied] = useState(false);

  const handleShare = () => {
    const shareText = `저는 ${result.name} (${resultType}) 입니다! 당신의 영업 스타일은 무엇일까요? 지금 바로 진단해보세요!`;
    const shareUrl = window.location.href;

    if (navigator.share) {
      navigator.share({
        title: 'My Sales Persona 진단 결과',
        text: shareText,
        url: shareUrl,
      })
      .then(() => console.log('Share successful'))
      .catch((error) => {
        console.error('Web Share API failed:', error);
        setShowShareModal(true);
      });
    } else {
      setShowShareModal(true);
    }
  };

  const generateSalesTips = async () => {
    setIsGeneratingTips(true);
    setSalesTips('');

    const prompt = `Based on the sales persona type '${resultType}' with the following axis scores: APPROACH: ${axisScores.APPROACH}, VALUE: ${axisScores.VALUE}, RELATIONSHIP: ${axisScores.RELATIONSHIP}, DECISION: ${axisScores.DECISION}. Please provide 3 actionable, concise sales tips specifically tailored to this persona. Focus on leveraging their strengths and addressing potential weaknesses. Respond in Korean.`;

    let chatHistory = [];
    chatHistory.push({ role: "user", parts: [{ text: prompt }] });

    const payload = { contents: chatHistory };
    const apiKey = "";
    const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`;

    try {
      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      const resultData = await response.json();

      if (resultData.candidates && resultData.candidates.length > 0 &&
          resultData.candidates[0].content && resultData.candidates[0].content.parts &&
          resultData.candidates[0].content.parts.length > 0) {
        const text = resultData.candidates[0].content.parts[0].text;
        if (typeof text === 'string' && text.trim().length > 0) {
          setSalesTips(text);
        } else {
          console.warn("API returned empty or non-string text:", text);
          setSalesTips('팁을 생성하는 데 실패했습니다. 유효한 팁을 받을 수 없습니다.');
        }
        setShowTipsModal(true);
      } else {
        console.error("API response structure unexpected or empty content:", resultData);
        setSalesTips('팁을 생성하는 데 실패했습니다. 응답 형식을 확인해 주세요.');
        setShowTipsModal(true);
      }
    } catch (error) {
      console.error("Error generating sales tips:", error);
      setSalesTips('팁을 생성하는 중 오류가 발생했습니다. 네트워크 또는 API 설정을 확인해 주세요.');
      setShowTipsModal(true);
    } finally {
      setIsGeneratingTips(false);
    }
  };

  const axisLabels = {
    APPROACH: '접근 방식 (R: 반응적 ↔ P: 적극적)',
    VALUE: '가치 전달 방식 (F: 서비스 ↔ S: 솔루션)',
    RELATIONSHIP: '관계 구축 방식 (T: 성과/효율 ↔ E: 감정적)',
    DECISION: '의사결정 스타일 (C: 팀 협의 ↔ I: 개인 주도)',
  };

  // Function to copy text to clipboard (iFrame compatible)
  const copyToClipboard = (textToCopy) => {
    const textArea = document.createElement('textarea');
    textArea.value = textToCopy;
    document.body.appendChild(textArea);
    textArea.select();
    try {
      document.execCommand('copy');
      setIsCopied(true);
      setTimeout(() => setIsCopied(false), 2000);
    } catch (err) {
      console.error('Clipboard copy failed (execCommand):', err);
      if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(textToCopy).then(() => {
          setIsCopied(true);
          setTimeout(() => setIsCopied(false), 2000);
        }).catch(clipErr => {
          console.error('Clipboard copy failed (navigator.clipboard):', clipErr);
        });
      }
    }
    document.body.removeChild(textArea);
  };


  return (
    <div className="flex flex-col items-center min-h-screen bg-gray-50 p-4 sm:p-6 md:p-8">
      <div className="w-full max-w-xl bg-white rounded-2xl shadow-xl p-6 sm:p-8 text-center">
        <h1 className="text-3xl sm:text-4xl font-bold text-blue-600 mb-4">My Sales Persona</h1>
        <div className="flex flex-col items-center mb-6">
          <img
            src={result.illustration}
            alt={`${result.name} 캐릭터`}
            className="w-32 h-32 sm:w-40 sm:h-40 rounded-full mb-4 object-cover border-4 border-blue-200 shadow-md"
            onError={(e) => { e.target.onerror = null; e.target.src = "https://placehold.co/150x150/cccccc/ffffff?text=캐릭터"; }}
          />
          <h2 className="text-4xl sm:text-5xl font-extrabold text-blue-700 mb-2">{resultType}</h2>
          <p className="text-xl sm:text-2xl font-semibold text-gray-800">{result.name}</p>
        </div>

        <div className="text-left mb-8 space-y-6">
          {/* 성향 강도 그래프 */}
          <div className="bg-gray-50 p-5 rounded-xl shadow-inner">
            <h3 className="text-xl font-bold text-gray-800 mb-4">📊 성향 강도 그래프</h3>
            <p className="text-sm text-gray-600 mb-4">
              각 축별 점수와 성향 강도를 확인해보세요. 점수 범위는 -24점 ~ +24점입니다.
            </p>
            {Object.keys(axisScores).map((axis) => (
              <ScoreBar
                key={axis}
                label={axisLabels[axis]}
                score={axisScores[axis]}
                maxScore={maxAxisScore}
              />
            ))}
          </div>

          {/* 핵심 특성 */}
          {result.coreCharacteristics && result.coreCharacteristics.length > 0 && (
            <div className="bg-orange-50 p-5 rounded-xl shadow-inner">
              <h3 className="text-xl font-bold text-orange-700 mb-3">✨ 핵심 특성</h3>
              <ul className="list-disc list-inside text-gray-700 space-y-1">
                {result.coreCharacteristics.map((item, i) => <li key={i}>{item}</li>)}
              </ul>
            </div>
          )}

          {/* 영업 스타일 */}
          {result.salesStyle && result.salesStyle.length > 0 && (
            <div className="bg-blue-50 p-5 rounded-xl shadow-inner">
              <h3 className="text-xl font-bold text-blue-700 mb-3">💼 영업 스타일</h3>
              <ul className="list-disc list-inside text-gray-700 space-y-1">
                {result.salesStyle.map((item, i) => <li key={i}>{item}</li>)}
              </ul>
            </div>
          )}

          {/* 고객이 바라보는 당신의 모습 */}
          {result.고객이바라보는당신의모습 && (
            <div className="bg-blue-50 p-5 rounded-xl shadow-inner">
              <h3 className="text-xl font-bold text-blue-700 mb-3">👁 고객이 바라보는 당신의 모습</h3>
              <p className="text-gray-700">{result.고객이바라보는당신의모습}</p>
            </div>
          )}

          {/* 고객이 느끼는 당신의 성향 */}
          {result.고객이느끼는당신의성향 && (
            <div className="bg-green-50 p-5 rounded-xl shadow-inner">
              <h3 className="text-xl font-bold text-green-700 mb-3">🧭 고객이 느끼는 당신의 성향</h3>
              <p className="text-gray-700">{result.고객이느끼는당신의성향}</p>
            </div>
          )}

          {/* 고객이 경험하는 영업 스타일 */}
          {result.고객이경험하는영업스타일 && (
            <div className="bg-yellow-50 p-5 rounded-xl shadow-inner">
              <h3 className="text-xl font-bold text-yellow-700 mb-3">💼 고객이 경험하는 영업 스타일</h3>
              <p className="text-gray-700">{result.고객이경험하는영업스타일}</p>
            </div>
          )}

          {/* 강점 */}
          {result.강점 && result.강점.length > 0 && (
            <div className="bg-purple-50 p-5 rounded-xl shadow-inner">
              <h3 className="text-xl font-bold text-purple-700 mb-3">🌟 강점</h3>
              <ul className="list-disc list-inside text-gray-700 space-y-1">
                {result.강점.map((item, i) => <li key={i}>{item}</li>)}
              </ul>
            </div>
          )}

          {/* 약점 */}
          {result.약점 && result.약점.length > 0 && (
            <div className="bg-red-50 p-5 rounded-xl shadow-inner">
              <h3 className="text-xl font-bold text-red-700 mb-3">⚠ 약점</h3>
              <ul className="list-disc list-inside text-gray-700 space-y-1">
                {result.약점.map((item, i) => <li key={i}>{item}</li>)}
              </ul>
            </div>
          )}

          {/* 고객과의 궁합 */}
          {result.고객과의궁합 && (result.고객과의궁합.good?.length > 0 || result.고객과의궁합.bad?.length > 0) && (
            <div className="bg-indigo-50 p-5 rounded-xl shadow-inner">
              <h3 className="text-xl font-bold text-indigo-700 mb-3">🤝 고객과의 궁합</h3>
              {result.고객과의궁합.good && result.고객과의궁합.good.map((item, i) => <p key={`good-${i}`} className="text-gray-700">{item}</p>)}
              {result.고객과의궁합.bad && result.고객과의궁합.bad.map((item, i) => <p key={`bad-${i}`} className="text-gray-700">{item}</p>)}
            </div>
          )}

          {/* 추천 교육 */}
          {result.추천교육 && (
            <div className="bg-teal-50 p-5 rounded-xl shadow-inner">
              <h3 className="text-xl font-bold text-teal-700 mb-3">🎓 EXPERT의 Sales 맞춤 교육 제안</h3>
              <p className="text-gray-700 mb-2">
                <span className="font-semibold">교육명:</span> {result.추천교육.교육명}
              </p>
              <p className="text-gray-700 mb-2">
                <span className="font-semibold">교육 포인트:</span> {result.추천교육.교육포인트}
              </p>
              <p className="text-gray-700 mb-2">
                <span className="font-semibold">교육 방향:</span> {result.추천교육.교육방향}
              </p>
              <p className="text-gray-700">
                <span className="font-semibold">인사이트:</span> {result.추천교육.인사이트}
              </p>
            </div>
          )}
        </div>

        {/* User ID for debugging/sharing */}
        {userId && (
          <div className="text-sm text-gray-500 mb-6 p-3 bg-gray-100 rounded-lg break-all">
            사용자 ID: {userId}
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row justify-center space-y-4 sm:space-y-0 sm:space-x-4">
          <button
            onClick={generateSalesTips}
            disabled={isGeneratingTips}
            className="w-full sm:w-auto py-3 px-6 rounded-xl text-lg font-medium bg-green-500 text-white hover:bg-green-600 active:bg-green-700 shadow-md transition-all duration-200 ease-in-out flex items-center justify-center"
          >
            {isGeneratingTips ? (
              <svg className="animate-spin h-5 w-5 text-white mr-3" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
            ) : (
              '✨ 나만의 Sales 팁 받기'
            )}
          </button>
          <button
            onClick={handleShare}
            className="w-full sm:w-auto py-3 px-6 rounded-xl text-lg font-medium bg-purple-500 text-white hover:bg-purple-600 active:bg-purple-700 shadow-md transition-all duration-200 ease-in-out"
          >
            <i className="fas fa-share-alt mr-2"></i> SNS 공유
          </button>
          <button
            onClick={onRestart}
            className="w-full sm:w-auto py-3 px-6 rounded-xl text-lg font-medium bg-gray-100 text-gray-700 hover:bg-gray-200 active:bg-gray-300 shadow-sm transition-all duration-200 ease-in-out"
          >
            다시 진단하기
          </button>
        </div>

        {/* Sales Tips Modal */}
        {showTipsModal && (
          <div className="fixed inset-0 bg-gray-600 bg-opacity-75 flex items-center justify-center p-4 z-50">
            <div className="bg-white rounded-2xl shadow-2xl p-6 sm:p-8 max-w-md w-full relative">
              <h3 className="text-2xl font-bold text-blue-700 mb-4 text-center">✨ 개인화된 Sales 팁</h3>
              <div className="text-gray-800 text-left whitespace-pre-wrap mb-6 border border-gray-200 p-4 rounded-lg bg-gray-50 max-h-80 overflow-y-auto">
                {salesTips || "팁을 불러오는 중입니다..."}
              </div>
              <button
                onClick={() => setShowTipsModal(false)}
                className="w-full py-3 px-6 rounded-xl text-lg font-medium bg-blue-500 text-white hover:bg-blue-600 active:bg-blue-700 shadow-md transition-all duration-200 ease-in-out"
              >
                닫기
              </button>
            </div>
          </div>
        )}

        {/* Share Modal (for fallback) */}
        {showShareModal && (
          <div className="fixed inset-0 bg-gray-600 bg-opacity-75 flex items-center justify-center p-4 z-50">
            <div className="bg-white rounded-2xl shadow-2xl p-6 sm:p-8 max-w-md w-full relative">
              <h3 className="text-2xl font-bold text-blue-700 mb-4 text-center">공유하기</h3>
              <p className="text-gray-800 text-center mb-6">
                이 브라우저는 직접 공유 기능을 지원하지 않습니다.
                <br/>
                아래 내용을 복사하여 공유해 주세요:
              </p>
              <textarea
                readOnly
                value={`저는 ${result.name} (${resultType}) 입니다! 당신의 영업 스타일은 무엇일까요? 지금 바로 진단해보세요!\n${window.location.href}`}
                className="w-full p-3 border border-gray-300 rounded-lg mb-4 resize-none h-32 text-gray-700"
              />
              <button
                onClick={() => copyToClipboard(`저는 ${result.name} (${resultType}) 입니다! 당신의 영업 스타일은 무엇일까요? 지금 바로 진단해보세요!\n${window.location.href}`)}
                className="w-full py-3 px-6 rounded-xl text-lg font-medium bg-blue-500 text-white hover:bg-blue-600 active:bg-blue-700 shadow-md transition-all duration-200 ease-in-out mb-2"
              >
                클립보드에 복사
              </button>
              {isCopied && (
                <div className="absolute bottom-24 left-1/2 -translate-x-1/2 bg-green-500 text-white text-sm px-3 py-1 rounded-full shadow-lg transition-opacity duration-300">
                  클립보드에 복사되었습니다!
                </div>
              )}
              <button
                onClick={() => setShowShareModal(false)}
                className="w-full py-3 px-6 rounded-xl text-lg font-medium bg-gray-100 text-gray-700 hover:bg-gray-200 active:bg-gray-300 shadow-sm transition-all duration-200 ease-in-out"
              >
                닫기
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

// Main App Component
const App = () => {
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [userAnswers, setUserAnswers] = useState({});
  const [resultType, setResultType] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [db, setDb] = useState(null);
  const [auth, setAuth] = useState(null);
  const [userId, setUserId] = useState(null);
  const [isAuthReady, setIsAuthReady] = useState(false);
  const [axisScores, setAxisScores] = useState({ APPROACH: 0, VALUE: 0, RELATIONSHIP: 0, DECISION: 0 });


  // Initialize Firebase and set up auth listener
  useEffect(() => {
    if (app && dbInstance && authInstance) {
      setDb(dbInstance);
      setAuth(authInstance);

      const unsubscribe = onAuthStateChanged(authInstance, async (user) => {
        let currentUid = null;
        if (user) {
          currentUid = user.uid;
        } else {
          try {
            if (typeof __initial_auth_token !== 'undefined' && __initial_auth_token) {
              const userCredential = await signInWithCustomToken(authInstance, __initial_auth_token);
              currentUid = userCredential.user.uid;
            } else {
              const anonUser = await signInAnonymously(authInstance);
              currentUid = anonUser.user.uid;
            }
          } catch (error) {
            console.error("Login error:", error);
            currentUid = crypto.randomUUID();
          }
        }
        setUserId(currentUid);
        setIsAuthReady(true);
      });

      return () => unsubscribe();
    } else {
      setUserId(crypto.randomUUID());
      setIsAuthReady(true);
      setIsLoading(false);
    }
  }, []);

  // Load saved progress and answers from Firestore
  useEffect(() => {
    const loadProgress = async () => {
      if (!db || !userId || !isAuthReady) {
        setIsLoading(false);
        return;
      }

      try {
        const progressDocRef = doc(db, `artifacts/${appId}/users/${userId}/progress/current`);
        const progressDocSnap = await getDoc(progressDocRef);

        if (progressDocSnap.exists()) {
          const savedProgress = progressDocSnap.data();
          setCurrentQuestionIndex(savedProgress.currentQuestionIndex || 0);
        }

        const responsesCollectionRef = collection(db, `artifacts/${appId}/users/${userId}/responses`);
        const q = query(responsesCollectionRef);
        const querySnapshot = await getDocs(q);
        const loadedAnswers = {};
        querySnapshot.forEach((docSnap) => {
          const data = docSnap.data();
          const questionId = docSnap.id;
          loadedAnswers[questionId] = {
            optionId: data.selectedOptionId,
            score: data.score
          };
        });
        setUserAnswers(loadedAnswers);
      } catch (error) {
        console.error("Error loading progress or answers:", error);
      } finally {
        setIsLoading(false);
      }
    };

    if (isAuthReady) {
      loadProgress();
    }
  }, [db, userId, isAuthReady, appId]);

  // Save current progress to Firestore whenever currentQuestionIndex changes
  const saveProgress = useCallback(async (indexToSave) => {
    if (!db || !userId) {
      return;
    }
    try {
      const progressDocRef = doc(db, `artifacts/${appId}/users/${userId}/progress/current`);
      await setDoc(progressDocRef, { currentQuestionIndex: indexToSave }, { merge: true });
    } catch (error) {
      console.error("Error saving progress:", error);
    }
  }, [db, userId, appId]);

  // Calculate MBTI result based on new axes
  const calculateResult = useCallback(() => {
    const calculatedScores = { APPROACH: 0, VALUE: 0, RELATIONSHIP: 0, DECISION: 0 };

    Object.values(userAnswers).forEach((answer) => {
      if (answer && answer.score) {
        for (const trait in answer.score) {
          if (Object.prototype.hasOwnProperty.call(calculatedScores, trait) && typeof answer.score[trait] === 'number') {
            calculatedScores[trait] += answer.score[trait];
          }
        }
      }
    });

    setAxisScores(calculatedScores);

    let type = '';
    type += calculatedScores.APPROACH >= 0 ? 'P' : 'R';
    type += calculatedScores.VALUE >= 0 ? 'S' : 'F';
    type += calculatedScores.RELATIONSHIP >= 0 ? 'E' : 'T';
    type += calculatedScores.DECISION >= 0 ? 'I' : 'C';

    setResultType(type);
  }, [userAnswers]);


  // Handle user answer selection
  const handleAnswer = useCallback(async (questionId, optionId, score) => {
    const newAnswers = {
      ...userAnswers,
      [questionId]: { optionId, score },
    };
    setUserAnswers(newAnswers);

    // Save answer to Firestore
    if (db && userId) {
      try {
        const answerDocRef = doc(db, `artifacts/${appId}/users/${userId}/responses/${questionId}`);
        await setDoc(answerDocRef, { selectedOptionId: optionId, score: score, timestamp: new Date() }, { merge: true });
      } catch (error) {
        console.error("Error saving answer:", error);
      }
    }

    // Automatically advance to the next question
    if (currentQuestionIndex < questionsData.length - 1) {
      const nextIndex = currentQuestionIndex + 1;
      setCurrentQuestionIndex(nextIndex);
      saveProgress(nextIndex);
    } else {
      const tempScores = { APPROACH: 0, VALUE: 0, RELATIONSHIP: 0, DECISION: 0 };
      Object.values(newAnswers).forEach((answer) => {
        if (answer && answer.score) {
          for (const trait in answer.score) {
            if (Object.prototype.hasOwnProperty.call(tempScores, trait) && typeof answer.score[trait] === 'number') {
              tempScores[trait] += answer.score[trait];
            }
          }
        }
      });
      setAxisScores(tempScores);
      let type = '';
      type += tempScores.APPROACH >= 0 ? 'P' : 'R';
      type += tempScores.VALUE >= 0 ? 'S' : 'F';
      type += tempScores.RELATIONSHIP >= 0 ? 'E' : 'T';
      type += tempScores.DECISION >= 0 ? 'I' : 'C';
      setResultType(type);
    }

  }, [userAnswers, db, userId, currentQuestionIndex, saveProgress, appId]);


  // Navigate to the previous question
  const handlePrev = useCallback(() => {
    if (currentQuestionIndex > 0) {
      const prevIndex = currentQuestionIndex - 1;
      setCurrentQuestionIndex(prevIndex);
      saveProgress(prevIndex);
    }
  }, [currentQuestionIndex, saveProgress]);


  // Restart the test
  const handleRestart = useCallback(async () => {
    setCurrentQuestionIndex(0);
    setUserAnswers({});
    setResultType(null);
    setAxisScores({ APPROACH: 0, VALUE: 0, RELATIONSHIP: 0, DECISION: 0 });

    // Clear saved progress and answers in Firestore
    if (db && userId) {
      try {
        const batch = writeBatch(db);
        const progressDocRef = doc(db, `artifacts/${appId}/users/${userId}/progress/current`);
        batch.set(progressDocRef, { currentQuestionIndex: 0 });

        const responsesCollectionRef = collection(db, `artifacts/${appId}/users/${userId}/responses`);
        const q = query(responsesCollectionRef);
        const querySnapshot = await getDocs(q);
        querySnapshot.forEach((docSnap) => {
          batch.delete(docSnap.ref);
        });
        await batch.commit();
      } catch (error) {
        console.error("Error resetting progress or answers:", error);
      }
    }
  }, [db, userId, appId]);

  // Calculate result when all answers are loaded (e.g., on initial load)
  useEffect(() => {
    if (Object.keys(userAnswers).length === questionsData.length && questionsData.length > 0 && !resultType) {
        calculateResult();
    }
  }, [userAnswers, questionsData.length, resultType, calculateResult]);


  if (isLoading || !isAuthReady) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-50">
        <div className="text-xl font-semibold text-blue-600">로딩 중...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center font-inter antialiased">
      {resultType ? (
        <ResultPage
          resultType={resultType}
          mbtiResultsData={mbtiResultsData}
          onRestart={handleRestart}
          userId={userId}
          axisScores={axisScores}
        />
      ) : (
        <QuestionPage
          question={questionsData[currentQuestionIndex]}
          questionIndex={currentQuestionIndex}
          totalQuestions={questionsData.length}
          onAnswer={handleAnswer}
          onPrev={handlePrev}
          selectedOptionId={userAnswers[questionsData[currentQuestionIndex]?.id]?.optionId}
        />
      )}
    </div>
  );
};

export default App;
