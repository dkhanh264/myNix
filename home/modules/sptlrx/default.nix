{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    sptlrx
  ];

  xdg.configFile."sptlrx/config.yaml".text = ''
    cookie: "AQDeKTf4HWHXHwwGtDHZGC0Se7tIZx13cI_SVL6F7xH3kt_VP56cbB7WLdeb7fuV1ErGP4iwEfR8417TKy-Swbj4RN__ZsqWg8iiINPIAACahynAIOTQpJkjM7o5mE0DvxnoWG4QFK4NXT4YM32pg-JDOVdmBsylYWUckh_zvf2ScZBVaKKNk55H00NfDvwvMgwrCEq3yGGKIubaLklNkWHIYHcH37lGas3Z_FE6aw5rQ04zp1xPxY4Fvp2S5YIjSyTw5lOs19voYVQ"
    player: mpris
    host: lyricsapi.vercel.app
    ignoreErrors: false
    timerInterval: 200
    updateInterval: 1000
    style:
      hAlignment: center
      before:
        background: ""
        foreground: "#6c7086"
        bold: false
        faint: true
      current:
        background: ""
        foreground: "#cba6f7"
        bold: true
        italic: false
      after:
        background: ""
        foreground: "#a6adc8"
        bold: false
        faint: true
    pipe:
      length: 0
      overflow: word
    mpris:
      players: ["spotify"]
  '';
}
