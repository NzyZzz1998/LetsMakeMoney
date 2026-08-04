import { Clock3 } from "lucide-react";
import { useEffect, useId, useLayoutEffect, useRef, useState, type KeyboardEvent } from "react";
import {
  formatTimeValue,
  moveTimePart,
  parseTimeValue,
  shouldTimeFieldOpenUp,
} from "./timeFieldModel";

export function TimeField({
  label,
  value,
  onChange,
  readOnly = false,
  disabled = false,
  error,
  showError = true,
}: {
  label: string;
  value: string;
  onChange?(value: string): void;
  readOnly?: boolean;
  disabled?: boolean;
  error?: string;
  showError?: boolean;
}) {
  const id = useId();
  const rootRef = useRef<HTMLDivElement>(null);
  const controlRef = useRef<HTMLDivElement>(null);
  const popoverRef = useRef<HTMLDivElement>(null);
  const hourRefs = useRef<Array<HTMLButtonElement | null>>([]);
  const minuteRefs = useRef<Array<HTMLButtonElement | null>>([]);
  const [open, setOpen] = useState(false);
  const [opensUp, setOpensUp] = useState(false);
  const initial = parseTimeValue(value);
  const [hour, setHour] = useState(initial.hour);
  const [minute, setMinute] = useState(initial.minute);

  const openPicker = () => {
    if (readOnly || disabled) return;
    const next = parseTimeValue(value);
    setHour(next.hour);
    setMinute(next.minute);
    setOpen(true);
  };

  useEffect(() => {
    if (!open) return;
    const handlePointerDown = (event: PointerEvent) => {
      if (!rootRef.current?.contains(event.target as Node)) setOpen(false);
    };
    const handleKeyDown = (event: globalThis.KeyboardEvent) => {
      if (event.key === "Escape") setOpen(false);
    };
    const handleResize = () => setOpen(false);
    document.addEventListener("pointerdown", handlePointerDown);
    document.addEventListener("keydown", handleKeyDown);
    window.addEventListener("resize", handleResize);
    return () => {
      document.removeEventListener("pointerdown", handlePointerDown);
      document.removeEventListener("keydown", handleKeyDown);
      window.removeEventListener("resize", handleResize);
    };
  }, [open]);

  useLayoutEffect(() => {
    if (!open || !controlRef.current || !popoverRef.current) return;
    const controlRect = controlRef.current.getBoundingClientRect();
    const popoverHeight = popoverRef.current.getBoundingClientRect().height;
    setOpensUp(shouldTimeFieldOpenUp({
      triggerTop: controlRect.top,
      triggerBottom: controlRect.bottom,
      popoverHeight,
      viewportHeight: window.innerHeight,
    }));

    const selectedOptions = popoverRef.current.querySelectorAll<HTMLElement>(
      '[role="option"][aria-selected="true"]',
    );
    selectedOptions.forEach(option => option.scrollIntoView({ block: "center" }));
    window.requestAnimationFrame(() => hourRefs.current[hour]?.focus());
  }, [open]);

  const apply = () => {
    onChange?.(formatTimeValue(hour, minute));
    setOpen(false);
  };

  const movePart = (
    event: KeyboardEvent<HTMLButtonElement>,
    part: "hour" | "minute",
    value: number,
  ) => {
    if (!["ArrowDown", "ArrowUp", "Home", "End", "ArrowLeft", "ArrowRight"].includes(event.key)) return;
    event.preventDefault();
    if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
      const target = part === "hour" ? minuteRefs.current[minute] : hourRefs.current[hour];
      target?.focus();
      return;
    }
    const next = moveTimePart(value, event.key as "ArrowDown" | "ArrowUp" | "Home" | "End", part === "hour" ? 23 : 59);
    if (part === "hour") {
      setHour(next);
      window.requestAnimationFrame(() => hourRefs.current[next]?.focus());
    } else {
      setMinute(next);
      window.requestAnimationFrame(() => minuteRefs.current[next]?.focus());
    }
  };

  return (
    <div
      ref={rootRef}
      className={`field time-field ${open ? "is-open" : ""} ${opensUp ? "opens-up" : ""} ${readOnly ? "is-readonly" : ""} ${disabled ? "is-disabled" : ""} ${error ? "has-error" : ""}`}
      data-window-drag="false"
    >
      <span className="field__label" id={`${id}-label`}>{label}</span>
      <div ref={controlRef} className="time-field__control">
        <button
          type="button"
          className="time-field__trigger"
          aria-labelledby={`${id}-label ${id}-value`}
          aria-haspopup="dialog"
          aria-expanded={open}
          aria-readonly={readOnly}
          aria-invalid={Boolean(error)}
          aria-describedby={error ? `${id}-error` : undefined}
          disabled={disabled || readOnly}
          onClick={() => open ? setOpen(false) : openPicker()}
          onKeyDown={event => {
            if (!open && (event.key === "ArrowDown" || event.key === "ArrowUp")) {
              event.preventDefault();
              openPicker();
            }
          }}
        >
          <span id={`${id}-value`}>{value}</span>
          <Clock3 aria-hidden="true" size={17} strokeWidth={1.8} />
        </button>
        {open && (
          <div ref={popoverRef} className="time-field__popover" role="dialog" aria-label={`${label}选择器`}>
            <div className="time-field__columns">
              <div className="time-field__column" role="listbox" aria-label="小时">
                {Array.from({ length: 24 }, (_, index) => (
                  <button
                    ref={element => { hourRefs.current[index] = element; }}
                    type="button"
                    role="option"
                    aria-selected={hour === index}
                    key={index}
                    onClick={() => setHour(index)}
                    onKeyDown={event => movePart(event, "hour", index)}
                  >
                    {String(index).padStart(2, "0")}
                  </button>
                ))}
              </div>
              <span className="time-field__separator" aria-hidden="true">:</span>
              <div className="time-field__column" role="listbox" aria-label="分钟">
                {Array.from({ length: 60 }, (_, index) => (
                  <button
                    ref={element => { minuteRefs.current[index] = element; }}
                    type="button"
                    role="option"
                    aria-selected={minute === index}
                    key={index}
                    onClick={() => setMinute(index)}
                    onKeyDown={event => movePart(event, "minute", index)}
                  >
                    {String(index).padStart(2, "0")}
                  </button>
                ))}
              </div>
            </div>
            <div className="time-field__actions">
              <button type="button" onClick={() => setOpen(false)}>取消</button>
              <button type="button" className="is-primary" onClick={apply}>确定</button>
            </div>
          </div>
        )}
      </div>
      {error && showError && <small id={`${id}-error`} className="time-field__error">{error}</small>}
      {error && !showError && <span id={`${id}-error`} className="sr-only">{error}</span>}
    </div>
  );
}
