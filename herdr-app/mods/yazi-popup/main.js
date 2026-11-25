// Browse the focused terminal's folder in yazi, images included, in a popup.

import { View, div } from "gpui-kit";
import { home, focused, openOverlay, closeOverlay, props } from "herdr";

export default class YaziPopup extends View {
  init() {
    openOverlay({
      mod: "popup-terminal",
      kind: "popup",
      width: 1,
      height: 1,
      frame: "none",
      props: {
        title: "Files",
        argv: ["yazi"],
        cwd: focused()?.cwd ?? home(),
        env: { EDITOR: "nvim", VISUAL: "nvim" },
        width: 0.85,
        height: 0.85,
      },
    });
    if (props()?.overlay) closeOverlay(props().overlay);
  }

  render() {
    return div();
  }
}
