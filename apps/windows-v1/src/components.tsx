import { forwardRef, useId, useState } from "react";
import {
  AlertTriangle,
  BriefcaseBusiness,
  CalendarDays,
  Check,
  ChevronLeft,
  ChevronRight,
  CircleX,
  Clock3,
  Coins,
  Moon,
  RefreshCw,
  RotateCcw,
  Settings,
  Sun,
  X,
  type LucideIcon,
} from "lucide-react";

const APP_ICONS = {
  alert: AlertTriangle,
  briefcase: BriefcaseBusiness,
  calendar: CalendarDays,
  check: Check,
  "chevron-left": ChevronLeft,
  "chevron-right": ChevronRight,
  clock: Clock3,
  close: X,
  coins: Coins,
  error: CircleX,
  moon: Moon,
  refresh: RefreshCw,
  reset: RotateCcw,
  settings: Settings,
  sun: Sun,
} satisfies Record<string, LucideIcon>;

export type AppIconName = keyof typeof APP_ICONS;

export function AppIcon({
  name,
  size = 18,
  strokeWidth = 1.8,
}: {
  name: AppIconName;
  size?: number;
  strokeWidth?: number;
}) {
  const Icon = APP_ICONS[name] ?? AlertTriangle;
  return <Icon aria-hidden="true" size={size} strokeWidth={strokeWidth} />;
}

export function Button({
  children,
  variant = "primary",
  className = "",
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary" | "ghost" | "danger";
}) {
  return <button className={`button button--${variant} ${className}`} type="button" {...props}>{children}</button>;
}

export function IconButton({
  label,
  icon,
  className = "",
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & { label: string; icon: AppIconName }) {
  return <button className={`icon-button ${className}`} type="button" aria-label={label} title={label} {...props}><AppIcon name={icon} /></button>;
}

export const Field = forwardRef<HTMLInputElement, React.InputHTMLAttributes<HTMLInputElement> & {
  label: string;
  suffix?: string;
  hint?: string;
  error?: string;
}>(function Field({ label, suffix, hint, error, className = "", ...props }, ref) {
  const id = useId();
  const helpId = `${id}-help`;
  return (
    <label className={`field ${error ? "field--error" : ""} ${className}`} htmlFor={id}>
      <span className="field__label">{label}</span>
      <span className="field__control">
        <input ref={ref} id={id} aria-describedby={hint || error ? helpId : undefined} aria-invalid={Boolean(error)} {...props} />
        {suffix && <span className="field__suffix">{suffix}</span>}
      </span>
      {(hint || error) && <small id={helpId} className="field__hint">{error || hint}</small>}
    </label>
  );
});

export function Switch({ label, defaultChecked = false, checked: controlled, onChange }: { label: string; defaultChecked?: boolean; checked?: boolean; onChange?(checked: boolean): void }) {
  const [internal, setInternal] = useState(defaultChecked);
  const checked = controlled ?? internal;
  return <button className="switch" type="button" role="switch" aria-label={label} aria-checked={checked} onClick={() => {
    const next = !checked;
    if (controlled === undefined) setInternal(next);
    onChange?.(next);
  }}><span /></button>;
}

export function SegmentedControl({
  options,
  value,
  onChange,
}: {
  options: Array<{ value: string; label: string; disabled?: boolean }>;
  value: string;
  onChange(value: string): void;
}) {
  return <div className="segmented">{options.map(option => <button type="button" key={option.value} disabled={option.disabled} className={value === option.value ? "is-active" : ""} onClick={() => onChange(option.value)}>{option.label}</button>)}</div>;
}

export function ProgressBar({ value, label, compact = false }: { value: number; label: string; compact?: boolean }) {
  return <div className={`progress ${compact ? "progress--compact" : ""}`} aria-label={`${label} ${value}%`} role="progressbar" aria-valuemin={0} aria-valuemax={100} aria-valuenow={value}><span className="progress__track"><i style={{ width: `${value}%` }} /></span>{!compact && <span className="progress__meta"><span>{label}</span><strong>{value}%</strong></span>}</div>;
}

export function Feedback({ children, tone }: { children: React.ReactNode; tone: "success" | "warning" | "error" }) {
  return <div className={`feedback feedback--${tone}`} role={tone === "error" ? "alert" : "status"}><AppIcon name={tone === "success" ? "check" : tone === "warning" ? "alert" : "error"} size={16} />{children}</div>;
}
