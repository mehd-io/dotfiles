// A program in a floating dialog that closes when the program exits, like a
// herdr TUI plugin overlay pane.
//
// Mods can't import each other, so launchers (tiny mods that keys.json opens
// with `mod.open:<name>`) open this one as an invisible popup with
// props { title, argv, cwd?, env?, width?, height? }: it starts the program,
// opens the dialog and closes itself. In the dialog it is the title bar
// (props { title, terminal }).

import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { hc, home, openOverlay, closeOverlay, run, theme, props, notify } from "herdr";

async function popup({ title, argv, cwd, env = {}, width = 0.72, height = 0.78 }) {
  const vars = Object.entries(env).map(([k, v]) => `${k}=${v}`);
  // Unlabeled, so it stays out of the spaces; --rm drops it once it exits.
  const r = await hc(["run", "--bg", "--json", "--rm", "--cwd", cwd ?? home(), "--", "env", ...vars, ...argv]);
  if (r.code !== 0) throw new Error((r.stderr || r.stdout).trim());
  const out = JSON.parse(r.stdout);
  const terminal = out.address ?? out.terminal;
  openOverlay({
    kind: "dialog",
    modal: true,
    width,
    height,
    layout: {
      type: "column",
      children: [
        { type: "block", size: { px: 30 }, content: { mod: "popup-terminal", props: { title, terminal } } },
        { type: "block", content: { terminal } },
      ],
    },
  });
}

export default class PopupTerminal extends View {
  init(_props, cx) {
    const p = props() ?? {};
    if (!p.argv) return;
    cx.spawn(async () => {
      try {
        await popup(p);
      } catch (e) {
        notify({ title: `Couldn't open ${p.title ?? p.argv[0]}`, body: String(e?.message ?? e), level: "error" });
      }
      closeOverlay(p.overlay);
    });
  }

  render() {
    const { title, terminal, argv } = props() ?? {};
    if (argv) return div();
    const t = theme();
    return h_flex()
      .size_full()
      .px(12)
      .gap(8)
      .items_center()
      .bg(t.chrome)
      .text_size(12)
      .child(div().flex_1().truncate().text_color(t.muted).child(title ?? ""))
      .child(
        div()
          .id("popup-close")
          .px(6)
          .rounded(4)
          .text_color(t.dim)
          .cursor_pointer()
          .hover((s) => s.bg(t.hover).text_color(t.foreground))
          .on_click(() => run("terminal.kill", { terminal }))
          .child("✕"),
      );
  }
}
