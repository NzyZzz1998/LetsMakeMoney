import {
  useEffect,
  useId,
  useLayoutEffect,
  useRef,
  useState,
  type KeyboardEvent,
} from "react";

import { AppIcon } from "../components";
import {
  comboboxKeyAction,
  selectedComboboxIndex,
  shouldComboboxOpenUp,
} from "./comboboxModel";

export interface ComboboxOption<Value extends string> {
  value: Value;
  label: string;
  disabled?: boolean;
}

export function AccessibleCombobox<Value extends string>({
  ariaLabel,
  value,
  options,
  onChange,
  placeholder = "请选择",
  disabled = false,
  error,
  showError = true,
}: {
  ariaLabel: string;
  value: Value | "";
  options: readonly ComboboxOption<Value>[];
  onChange(value: Value): void;
  placeholder?: string;
  disabled?: boolean;
  error?: string;
  showError?: boolean;
}) {
  const baseId = useId();
  const listboxId = `${baseId}-listbox`;
  const errorId = `${baseId}-error`;
  const rootRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const listboxRef = useRef<HTMLDivElement>(null);
  const optionRefs = useRef<Array<HTMLButtonElement | null>>([]);
  const [open, setOpen] = useState(false);
  const [opensUp, setOpensUp] = useState(false);
  const [activeIndex, setActiveIndex] = useState(0);
  const values = options.map(option => option.value);
  const disabledOptions = options.map(option => Boolean(option.disabled));
  const selectedIndex = selectedComboboxIndex(value, values, disabledOptions);
  const selected = options.find(option => option.value === value);

  const close = (restoreFocus: boolean) => {
    setOpen(false);
    if (restoreFocus) window.requestAnimationFrame(() => triggerRef.current?.focus());
  };

  const openAt = (index: number) => {
    if (disabled || options.length === 0) return;
    setActiveIndex(index);
    setOpen(true);
  };

  const choose = (index: number) => {
    const option = options[index];
    if (!option || option.disabled) return;
    onChange(option.value);
    close(true);
  };

  const applyKeyAction = (event: KeyboardEvent, source: "trigger" | "listbox") => {
    const action = comboboxKeyAction({
      key: event.key,
      open,
      activeIndex,
      selectedIndex,
      optionCount: options.length,
      disabled: disabledOptions,
    });
    if (action.type === "none") return;
    if (action.type !== "close" || event.key !== "Tab") event.preventDefault();
    if (action.type === "open") openAt(action.index);
    if (action.type === "move") setActiveIndex(action.index);
    if (action.type === "select") choose(source === "trigger" ? selectedIndex : activeIndex);
    if (action.type === "close") close(action.restoreFocus);
  };

  useLayoutEffect(() => {
    if (!open) return;
    const trigger = triggerRef.current;
    const listbox = listboxRef.current;
    if (!trigger || !listbox) return;
    const rect = trigger.getBoundingClientRect();
    setOpensUp(shouldComboboxOpenUp({
      triggerTop: rect.top,
      triggerBottom: rect.bottom,
      listHeight: listbox.scrollHeight,
      viewportHeight: window.innerHeight,
    }));
    optionRefs.current[activeIndex]?.focus();
  }, [activeIndex, open]);

  useEffect(() => {
    if (!open) return;
    const handlePointerDown = (event: PointerEvent) => {
      if (!rootRef.current?.contains(event.target as Node)) close(false);
    };
    const handleResize = () => close(false);
    document.addEventListener("pointerdown", handlePointerDown);
    window.addEventListener("resize", handleResize);
    return () => {
      document.removeEventListener("pointerdown", handlePointerDown);
      window.removeEventListener("resize", handleResize);
    };
  }, [open]);

  return (
    <div
      ref={rootRef}
      className={`accessible-combobox ${open ? "is-open" : ""} ${opensUp ? "opens-up" : ""} ${error ? "has-error" : ""}`}
      data-window-drag="false"
    >
      <button
        ref={triggerRef}
        type="button"
        className="accessible-combobox__trigger"
        role="combobox"
        aria-label={ariaLabel}
        aria-controls={listboxId}
        aria-expanded={open}
        aria-haspopup="listbox"
        aria-invalid={Boolean(error)}
        aria-describedby={error ? errorId : undefined}
        disabled={disabled}
        onClick={() => open ? close(false) : openAt(selectedIndex)}
        onKeyDown={event => applyKeyAction(event, "trigger")}
      >
        <span>{selected?.label ?? placeholder}</span>
        <AppIcon name="chevron-down" size={16} />
      </button>
      <div
        ref={listboxRef}
        id={listboxId}
        className="accessible-combobox__listbox"
        role="listbox"
        aria-label={ariaLabel}
        hidden={!open}
        onKeyDown={event => applyKeyAction(event, "listbox")}
      >
        {options.map((option, index) => (
          <button
            ref={element => { optionRefs.current[index] = element; }}
            id={`${baseId}-option-${index}`}
            key={option.value}
            type="button"
            role="option"
            aria-selected={option.value === value}
            disabled={option.disabled}
            tabIndex={-1}
            onClick={() => choose(index)}
            onPointerMove={() => setActiveIndex(index)}
          >
            {option.label}
          </button>
        ))}
      </div>
      {error && showError && <small id={errorId} className="accessible-combobox__error">{error}</small>}
      {error && !showError && <span id={errorId} className="sr-only">{error}</span>}
    </div>
  );
}
