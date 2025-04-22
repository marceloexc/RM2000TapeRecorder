<div align="center">
<img src="https://raw.githubusercontent.com/marceloexc/RM2000TapeRecorder/refs/heads/master/Images/Header.webp" width="700">
<p>effortless audio recording and organizing</p>
<p><a href="https://rm2000.app">rm2000.app</a></p>
</div>

<br>

RM2000 Tape Recorder is a lightweight audio sampling tool for macOS. quickly record audio samples from any application, organize them with tags, and sort through them through your daw, the finder, or RM2000 itself

> [!NOTE]
>
> RM2000 is currently under heavy development - however, a TestFlight version to test for bugs and crashes is publicly [available here](https://rm2000.app)

## power of persuasion

RM2000 features a beautiful skeuomorphic interface to mimic the look and feel of a bygone era of Mac Apps

my goal is make the app stand out from the current flat designs that apple has pushed and advocated for since the release of macOS yosemite.

<div align="center">
<figure>
<img src="https://upload.wikimedia.org/wikipedia/en/6/6c/Replica_%28Front_Cover%29.png" width="148" height="148" style="margin: 0 10px">
<figcaption>originally codenamed <code>replica.app</code>. this app was <i>heavily</i> inspired by <a href="https://www.youtube.com/watch?v=PU0g45uEI84">opn's work</a></figcaption>
</figure>
</div>

# building

RM2000 Portable requires Xcode and macOS 13 or newer.

It is recommended to have a Development Signing Certificate active on Xcode so that the Screen Recording permission dialog doesn't show up after every single build. A **Development Signing Certificate** is not the same as an **Apple Developer ID** and is completely free to make.

1. open the settings for `RM2000.xcodeproj`

2. go to the `Signing and Capabilities` tab

3. selecting the `rm2000` target

4. create a new Development team and set Signing Certificate as "Development"

