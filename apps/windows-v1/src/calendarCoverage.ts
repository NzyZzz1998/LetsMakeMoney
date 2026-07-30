export type CalendarCoverageMode =
  | "official"
  | "estimated"
  | "stale"
  | "integrity_error";

export type CalendarEstimateBasis = "double" | "single" | "alternating";

export interface CalendarSource {
  publisher: string;
  title: string;
  document_no: string;
  published_at: string;
  url: string;
}

export interface CalendarCoverage {
  year: number;
  mode: CalendarCoverageMode;
  dataset_version: string | null;
  source: CalendarSource | null;
  estimate_basis: CalendarEstimateBasis | null;
  stale_reason: string | null;
  error_code: string | null;
  official: boolean;
  can_adjust_date: boolean;
}

export type CalendarLoadFailureKind = "unsupported" | "integrity_error";

export function createOfficialCoverage(
  year: number,
  datasetVersion: string,
  source: CalendarSource,
): CalendarCoverage {
  return {
    year,
    mode: "official",
    dataset_version: datasetVersion,
    source,
    estimate_basis: null,
    stale_reason: null,
    error_code: null,
    official: true,
    can_adjust_date: true,
  };
}

export function createEstimatedCoverage(
  year: number,
  basis: CalendarEstimateBasis,
): CalendarCoverage {
  return {
    year,
    mode: "estimated",
    dataset_version: null,
    source: null,
    estimate_basis: basis,
    stale_reason: null,
    error_code: null,
    official: false,
    can_adjust_date: true,
  };
}

export function createStaleCoverage(
  coverage: CalendarCoverage,
  reason: string,
): CalendarCoverage {
  return {
    ...coverage,
    mode: "stale",
    stale_reason: reason,
    error_code: reason,
    can_adjust_date: false,
  };
}

export function createIntegrityErrorCoverage(
  year: number,
  errorCode: string,
): CalendarCoverage {
  return {
    year,
    mode: "integrity_error",
    dataset_version: null,
    source: null,
    estimate_basis: null,
    stale_reason: null,
    error_code: errorCode,
    official: false,
    can_adjust_date: false,
  };
}

export function classifyCalendarLoadFailure(
  errorCode: string,
  requestedYear: number,
): CalendarLoadFailureKind {
  return errorCode === `calendar_year_unsupported:${requestedYear}`
    ? "unsupported"
    : "integrity_error";
}
