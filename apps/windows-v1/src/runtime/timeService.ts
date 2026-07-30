export interface TimeService {
  now(): Date;
  wallClockMs(): number;
  monotonicMs(): number;
  timezoneId(): string;
  timezoneOffsetMinutes(): number;
}

export class SystemTimeService implements TimeService {
  now() {
    return new Date();
  }

  wallClockMs() {
    return Date.now();
  }

  monotonicMs() {
    return typeof performance === "undefined" ? Date.now() : performance.now();
  }

  timezoneId() {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || "local";
  }

  timezoneOffsetMinutes() {
    return new Date().getTimezoneOffset();
  }
}

export class FixedTimeService implements TimeService {
  constructor(
    private readonly value: Date,
    private readonly monotonicValue = 0,
    private readonly fixedTimezoneId = "fixed",
  ) {}

  now() {
    return new Date(this.value.getTime());
  }

  wallClockMs() {
    return this.value.getTime();
  }

  monotonicMs() {
    return this.monotonicValue;
  }

  timezoneId() {
    return this.fixedTimezoneId;
  }

  timezoneOffsetMinutes() {
    return this.value.getTimezoneOffset();
  }
}

function twoDigits(value: number) {
  return String(value).padStart(2, "0");
}

export function formatLocalDate(value: Date) {
  return `${value.getFullYear()}-${twoDigits(value.getMonth() + 1)}-${twoDigits(value.getDate())}`;
}

export function formatLocalTime(value: Date) {
  return `${twoDigits(value.getHours())}:${twoDigits(value.getMinutes())}:${twoDigits(value.getSeconds())}`;
}

export function monthKey(value: Date) {
  return `${value.getFullYear()}-${twoDigits(value.getMonth() + 1)}`;
}

export const systemTime = new SystemTimeService();
