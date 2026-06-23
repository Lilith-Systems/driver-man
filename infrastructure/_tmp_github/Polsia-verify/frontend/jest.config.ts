import type { Config } from "jest";

const config: Config = {
  testEnvironment: "jsdom",
  transform: { "^.+\\.tsx?$": "ts-jest" },
  moduleNameMapper: { "^@/(.*)$": "<rootDir>/src/$1" },
  setupFilesAfterEnv: ["<rootDir>/src/__tests__/setup.ts"],
  coverageThreshold: {
    global: { branches: 60, functions: 70, lines: 70 },
  },
};

export default config;
