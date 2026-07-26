# Lock screen videos

Drop a looping video here, then run `kde/apply-lockscreen.sh`. It picks the
first `.mp4` / `.webm` / `.mkv` in this directory, sorted by name.

What works well:

- **Short and seamless.** 10–30s that loops cleanly. Nobody stares at a lock
  screen long enough to want a plot.
- **Match the panel.** Something dark enough that the Mocha clock and password
  field stay readable on top of it.
- **Keep it small.** GitHub warns past 50MB and rejects past 100MB. Re-encode
  before committing:

  ```sh
  ffmpeg -i in.mp4 -an -c:v libx264 -crf 26 -preset slow -vf scale=2560:-2 out.mp4
  ```

  `-an` strips the audio track entirely — the greeter is force-muted anyway, so
  it is dead weight.

If your loop is genuinely too big to commit, keep it outside the repo and pass
the path instead: `kde/apply-lockscreen.sh /path/to/video.mp4`.
