# TalkingPet

As voice system developers, we often manually test different use cases. Testing with multiple actors can be complicated (i.e., Alice calls Bob, who adds Carol to the call).

Here is a micro-tool based on the [PJSUA SIP client](https://www.pjsip.org/pjsua.htm).

## Why TalkingPet?

The name is inspired by an alien from the [famous computer game](https://en.wikipedia.org/wiki/Star_Control_II).

![Talking pet](./docs/pics/talkingpet.jpg)

## Usage Instructions

1. Build it for the first time:

   ```bash
   docker-compose build --force-rm --no-cache --pull talkingpet
   ```

2. Configure the tool by creating an `.env` file from the provided `.env-sample`.

3. Execute one of the desired scripts:

   - `register SIP_USERNAME`: Register a SIP client and allow the tester to control it using keyboard shortcuts.
   - `answer SIP_USERNAME`: Register a SIP client and automatically answer incoming calls.
   - `play SIP_USERNAME /path/to/the/audio.wav`: Register a SIP client, answer incoming calls, and play back the given WAV file.
   - `dial SIP_USERNAME DESTINATION`: Dial a destination and enable the tester to control the call flow.
   - `broadcast SIP_USERNAME DESTINATION /path/to/audio.wav`: Dial a destination and play an audio file.
   - `tts /path/to/the/audio "Some voice announcement"`: Use text-to-speech for announcements.

Use `play` and `broadcast` to test RTP streams and audio quality or to assess call recording functionality by capturing SIP and RTP dumps with the `sngrep` utility and analyzing them with Wireshark.

**IMPORTANT:** Audio files used by `play` and `broadcast` must be converted to a compatible format. The `tts` script handles this, or you can use the `ffmpeg` utility (also within the Docker container):

```bash
ffmpeg -y -i SOURCE.wav -ar 8000 -ac 1 -ab 64K CONVERTED.wav
```

## Examples

When an inbound call reaches the conference and the user on SIP/0001 answers, the `/recordings/line_1.wav` announcement will be played to the calling party:

```bash
docker-compose run --rm --service-ports pjsua play 0001 /recordings/line_1.wav
```

Dial `00491234567890` from the trunk, and as soon as Asterisk answers, start playing the announcement `/recordings/trunk.wav`:

```bash
docker-compose run --rm --service-ports pjsua broadcast trunk 00491234567890 /recordings/trunk.wav
```

Use both cases to test call transfers (broadcast as a trunk, receive the call as agent 0003, and transfer it to 0001).

## Configuration

Configuration settings are in the `.env` file. **IMPORTANT:** Except for `SIP_USERNAME`, it shares the same configuration options. There are two ways to provide different credentials, such as a SIP password:

- Copy the whole folder and use a different `.env` file.
- Use the `-e KEY=VAL` argument with `docker-compose`:

   ```bash
   docker-compose run --rm --service-ports -e SIP_PASSWORD=foobar \
                      pjsua play 0001 /recordings/line_1.wav
   ```

## Troubleshooting

This test tool is based on Alpine Linux and runs in a Docker container. To troubleshoot, enter the container using:

```bash
docker-compose run --rm --service-ports --entrypoint=sh pjsua
```

You can add necessary tools such as `vim` or `sngrep` using:

```bash
apk add sngrep mc vim
```
