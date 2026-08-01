import { privacyTabPresentation } from "../src/features/mini/privacyTabPresentation";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}

const cases = [
  {
    name: "loading",
    input: { state: "loading" as const },
    expected: "正在同步",
  },
  {
    name: "error",
    input: { state: "error" as const },
    expected: "点击展开查看",
  },
  {
    name: "before work",
    input: {
      state: "ready" as const,
      phase: "before_work" as const,
      nextBoundaryKind: "work_start" as const,
      nextBoundarySeconds: 90 * 60,
    },
    expected: "距离上班 1小时30分",
  },
  {
    name: "working before rest",
    input: {
      state: "ready" as const,
      phase: "working" as const,
      nextBoundaryKind: "rest_start" as const,
      nextBoundarySeconds: 45 * 60,
    },
    expected: "距离休息 45分钟",
  },
  {
    name: "rest",
    input: {
      state: "ready" as const,
      phase: "lunch" as const,
      nextBoundaryKind: "work_resume" as const,
      nextBoundarySeconds: 30,
    },
    expected: "即将恢复工作",
  },
  {
    name: "working after rest",
    input: {
      state: "ready" as const,
      phase: "working" as const,
      nextBoundaryKind: "work_end" as const,
      nextBoundarySeconds: 100 * 60 * 60,
    },
    expected: "距离下班 99+小时",
  },
  {
    name: "after work",
    input: {
      state: "ready" as const,
      phase: "after_work" as const,
      nextBoundaryKind: null,
      nextBoundarySeconds: null,
    },
    expected: "今日工作已结束",
  },
  ...(["rest_day", "paid_rest", "unpaid_rest"] as const).map(phase => ({
    name: phase,
    input: {
      state: "ready" as const,
      phase,
      nextBoundaryKind: null,
      nextBoundarySeconds: null,
    },
    expected: "今日休息",
  })),
];

const forbidden = /(?:[¥￥$]|月薪|今日已赚|日薪|时薪|预计收入|收入进度|带薪|不带薪)/;
for (const testCase of cases) {
  const result = privacyTabPresentation(testCase.input);
  assert(result.visibleText === testCase.expected, `${testCase.name} visible copy drift`);
  assert(!forbidden.test(result.visibleText), `${testCase.name} visible copy leaks income policy`);
  assert(!forbidden.test(result.ariaLabel), `${testCase.name} ARIA leaks income policy`);
  assert(result.ariaLabel.includes("展开迷你收入视图"), `${testCase.name} ARIA lacks recovery action`);
}

console.log(`privacy tab presentation: ${cases.length}/${cases.length} passed`);
