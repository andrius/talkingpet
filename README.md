talkingpet
==========

As a voice systems developers we often manually test different use cases.
Testing with multiple actors could is complicated (i.e. Alice calls Bob, who
add a Carol to the call)

Here is a micro-tool, based on [PJSUA SIP client](https://www.pjsip.org/pjsua.htm).

# Why Talking Pet?

The name of alien from the [famous computer game](https://en.wikipedia.org/wiki/Star_Control_II)

![talkingpet](./docs/pics/talkingpet.jpg)

# Usage instructions

1) Build it first time:

```bash
docker-compose build --force-rm --no-cache --pull talkingpet
```

2) Configure (create an `.env` file from given `.env-sample`);

3) And then execute one of desired scripts:

- `register SIP_USERNAME` -- register SIP client and let tester control the
  SIP client using keyboard shortcuts;

- `answer SIP_USERNAME` -- register SIP client and automatically answer incoming
  calls;

- `play SIP_USERNAME /path/to/the/audio.wav` -- register SIP client, answer
  incoming calls and playback given wav file;

- `dial SIP_USERNAME DESTINATION` -- dial destination and let tester control
  call flow;

- `broadcast SIP_USERNAME DESTINATION /path/to/audio.wav` -- dial destination
  and play audio file;

or

- `tts /path/to/the/audio Some voice announcement`.

Use `play` and `broadcast` to test RTP streams and audio quality or to test
call recording functionality by capturing SIP+RTP dump with `sngrep` utility and
analysing it with Wireshark.

IMPORTANT! Audio files used by `play` and `broadcast` should be converted first
to the compatible format. `tts` script does that or user could using `ffmpeg`
utility (also within docker container):

```shell
ffmpeg -y -i SOURCE.wav -ar 8000 -ac 1 -ab 64K CONVERTED.wav
```

## Examples

When inbound call will hit the conference and user on SIP/0001 answer it,
announcement `/recordings/line_1.wav` will be played back to the calling party:

```shell
docker-compose run --rm --service-ports pjsua play 0001 /recordings/line_1.wav
```

Dial 00491234567890 from the trunk, and once Asterisk will answer, start
playing announcement /recordings/trunk.wav:

```shell
docker-compose run --rm --service-ports pjsua broadcast trunk 00491234567890 /recordings/trunk.wav
```

Use both cases to test call transfers (broadcast as a trunk, receive call as an
agent 0003 and transfer to the 0001).

# Configuration

Configuration settings are in the `.env` file. IMPORTANT: except the
`SIP_USERNAME`, it shares the same configuration options. There is two options
to provide different credentials, such as a SIP password:

- to copy whole folder and use different `.env`;
- or to use `-e KEY=VAL` argument with `docker-compose`:

    ```shell
    docker-compose run --rm --service-ports -e SIP_PASSWORD=foobar \
                   pjsua play 0001 /recordings/line_1.wav
    ```


# Troubleshooting

Test tool is based on Alpine linux and running in a docker, in order to
troubleshoot, just enter in:

```shell
docker-compose run --rm --service-ports --entrypoint=sh pjsua
```

Add necessary tools such as `vim` or `sngrep`:

```shell
apk add sngrep mc vim
```
