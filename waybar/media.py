#!/usr/bin/env python3
"""Waybar now-playing: "artist - title" of the last-active player, in a fixed-width box that scrolls when it doesn't fit."""
import html, json, os, subprocess, threading, time

WIDTH = 15  # characters; the CSS gives the module a monospace font so this is a fixed width on screen
GAP = "   •   "
TICK = 0.3  # seconds per scroll step

def frame(text, step, width=WIDTH):
    """The visible slice of text at a given scroll step: padded if it fits, otherwise a looping window."""
    if len(text) <= width:
        return text.ljust(width)
    loop = text + GAP
    i = step % len(loop)
    return (loop + loop)[i:i + width]

assert frame("abc", 5, 5) == "abc  "
assert frame("abcdef", 0, 4) == "abcd"
assert frame("abcdef", 4, 4) == "ef  "
assert frame("abcdef", len("abcdef" + GAP), 4) == "abcd"  # loops back to the start

state = {"status": "", "text": ""}

def follow():
    # One line per change from the last-active player; empty fields when nothing is loaded.
    p = subprocess.Popen(["playerctl", "-p", "playerctld", "--follow", "metadata", "--format",
                          "{{status}}\t{{artist}}\t{{title}}"], stdout=subprocess.PIPE, text=True)
    for line in p.stdout:
        status, artist, title = (line.rstrip("\n").split("\t") + ["", ""])[:3]
        state["status"] = status
        state["text"] = f"{artist} - {title}" if artist and title else title
    os._exit(1)  # playerctl died; Waybar's restart-interval starts us again

threading.Thread(target=follow, daemon=True).start()

HOLD = 3  # seconds an empty track must last before hiding, as a skip reports one briefly
step, last, shown, held, empty_since = 0, None, None, ("", ""), None
while True:
    text, status = state["text"], state["status"]
    if text:
        held, empty_since = (text, status), None
    else:
        empty_since = empty_since or time.monotonic()
        if time.monotonic() - empty_since < HOLD:
            text, status = held
    if text != last:
        step, last = 0, text  # a new song scrolls from its start
    out = json.dumps({"text": html.escape(frame(text, step)) if text else "", "alt": status})
    if out != shown:
        print(out, flush=True)
        shown = out
    step += 1
    time.sleep(TICK)
