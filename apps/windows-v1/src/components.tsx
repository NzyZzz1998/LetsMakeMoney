import { forwardRef, useId, useState } from "react";

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
}: React.ButtonHTMLAttributes<HTMLButtonElement> & { label: string; icon: string }) {
  return <button className={`icon-button ${className}`} type="button" aria-label={label} title={label} {...props}><span aria-hidden="true">{icon}</span></button>;
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
  return <div className={`feedback feedback--${tone}`} role={tone === "error" ? "alert" : "status"}><span aria-hidden="true">{tone === "success" ? "✓" : tone === "warning" ? "!" : "×"}</span>{children}</div>;
}
