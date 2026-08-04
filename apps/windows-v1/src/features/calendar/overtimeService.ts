import { appRuntime, type AppRuntime } from "../../runtime/appRuntime";
import type {
  OvertimeMutationResponse,
  OvertimeReadResponse,
} from "./overtimeModel";

export interface SaveOvertimeInput {
  businessDate: string;
  minutes: number;
  hourlyRateFenSnapshot: number;
}

export interface OvertimeService {
  readonly isDesktop: boolean;
  readDate(businessDate: string): Promise<OvertimeReadResponse>;
  readMonth(month: string): Promise<OvertimeReadResponse>;
  save(input: SaveOvertimeInput): Promise<OvertimeMutationResponse>;
  delete(businessDate: string): Promise<OvertimeMutationResponse>;
  recover(): Promise<OvertimeMutationResponse>;
  listenUpdated(handler: () => void): Promise<() => void>;
}

export function createOvertimeService(runtime: AppRuntime): OvertimeService {
  const publishIfChanged = async (result: OvertimeMutationResponse) => {
    if (["saved", "deleted", "recovered"].includes(result.status)) {
      await runtime.emit("lmm://overtime-updated", { status: result.status }).catch(() => undefined);
    }
    return result;
  };

  return {
    isDesktop: runtime.isDesktop,
    readDate: businessDate => runtime.invoke("read_overtime_record", { businessDate }),
    readMonth: month => runtime.invoke("read_overtime_month", { month }),
    save: input => runtime.invoke<OvertimeMutationResponse>("save_overtime_record", {
      request: {
        business_date: input.businessDate,
        minutes: input.minutes,
        hourly_rate_fen_snapshot: input.hourlyRateFenSnapshot,
      },
    }).then(publishIfChanged),
    delete: businessDate => runtime.invoke<OvertimeMutationResponse>("delete_overtime_record", {
      businessDate,
    }).then(publishIfChanged),
    recover: () => runtime.invoke<OvertimeMutationResponse>("recover_overtime_records")
      .then(publishIfChanged),
    listenUpdated: handler => runtime.listen("lmm://overtime-updated", handler),
  };
}

export const overtimeService = createOvertimeService(appRuntime);
