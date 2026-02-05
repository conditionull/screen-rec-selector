> [!IMPORTANT]
> This selector works in conjunction with [hyprdots](https://github.com/conditionull/hyprdots)<br />Using your own dots? Add this bind to hyprland.conf:<br />`bind = $mainMod SHIFT, R, exec, YOUR/PATH/TO/selector.sh`

Start a screen-recording with bind `SUPER+SHIFT+R` from hyprland.conf. It references a bashscript that utilizes the following dependencies:<br />
[gpu-screen-recorder](https://aur.archlinux.org/packages/gpu-screen-recorder), [kitty](https://sw.kovidgoyal.net/kitty/binary/), [fzf](https://wiki.archlinux.org/title/Fzf), [slurp](https://man.archlinux.org/man/extra/slurp/slurp.1.en), [coreutils](https://www.gnu.org/software/coreutils/), [libnotify](https://archlinux.org/packages/extra/x86_64/libnotify/), [waybar](https://wiki.archlinux.org/title/Waybar)<br />

> [!NOTE]
> The bind acts as a `toggle`; use it to start/stop the recording.<br /> Notifications are currently disabled since we'll be using an additional bash script to track the recording's duration via `waybar` module.

If you want the screen-recording notifications to display from your notification daemon, uncomment the notify-send lines in the bash file. I prefer the waybar module, it looks cleaner and gives you a headsup that you're recording in case you forget!

waybar recording_status module:<br />
<![recording_status module](/docs/images/image-4.png)<br />
<details>
    <summary>screen-rec-selector previews (click to view)</sdummary>

</details>

## Installation
```sh
git clone git@github.com:conditionull/screen-rec-selector.git
cd screen-rec-selector
chmod +x selector.sh
```
then use the full path in your `hyprland.conf`:
```sh
bind = $mainMod SHIFT, R, exec, YOUR/PATH/TO/selector.sh
```
Add the waybar module + module css (recommended)<br />
`waybar/config`
```
  "modules-right": [
    "custom/recording_status",
    "tray",
    "memory",
    "cpu",
    "wireplumber"
  ],
```
```
  "custom/recording_status": {
    "exec": "/home/doccia/workspace/github/screen-rec-selector/recording_status.sh",
    "interval": 1,
    "return-type": "json",
    "format": "{text}",
    "tooltip-format": " End recording: SUPER+SHIFT+R "
  }
```
`waybar/style.css` (customize the css to your liking; this styling works with my waybar)
```css
#custom-recording_status {
  border-radius: 8px;
  margin: 4px 4px;
  padding: 6px 10px;
  color: #ff5555;
  background-color: #1e1e2e;
  font-weight: 600;
  font-size: 12.5px;
}
```