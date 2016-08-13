
# Bromo : Broadcast monitor

![](/docs/img/logo.png)

音声・動画データを取得してposdcast形式で配信するサーバーです
単品の録音データを取得するのではなく、スケジュールリストから自動で録音・録画を行います。


## Make .bromorc.rb at ~/

See samples/bromorc.sample.rb

## Requirements

Mysql

## Installation

bundle install
RACK_ENV=production be rake db:migrate

## Usage

BASIC_AUTH_USERNAME=bromo BASIC_AUTH_PASSWORD=password RACK_ENV=production be ruby -I./lib ./bin/bromo

then access, http://localhost:7970/status

## Requirements

- rtmpdump
- ffmpeg

## TBD
- Currently anitama not working
- daemonize
- Gemfile
- Dockerfile



## License

Copyright (c) 2016 tetsutan.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
