import 'dart:async';
import 'dart:isolate';
import 'package:http/http.dart' as http;
import 'dart:convert' show JSON;

import 'package:flutter/foundation.dart';

import 'package:hn_flutter/sdk/services/abstract/hn_user_service.dart';
import 'package:hn_flutter/sdk/hn_config.dart';
import 'package:hn_flutter/sdk/models/hn_user.dart';
import 'package:hn_flutter/sdk/actions/hn_user_actions.dart';

class HNUserServiceProd implements HNUserService {
  static final _config = new HNConfig();
  final _receivePort = new ReceivePort();
  SendPort _sendPort;
  bool _initializing = false;

  Future<Null> _init () async {
    if (this._sendPort == null && !this._initializing) {
      this._initializing = true;
      await Isolate.spawn(_onMessage, this._receivePort.sendPort);
      this._sendPort = await _receivePort.first;
      this._initializing = false;
    } else if (this._initializing) {
      // TODO: figure out how to properly `await`
      do {
        await new Future.delayed(const Duration(milliseconds: 1));
      } while (this._initializing);
    }
  }

  static Future<Null> _onMessage (SendPort sendPort) async {
    final port = new ReceivePort();
    sendPort.send(port.sendPort);

    // handle message passing
    await for (final msg in port) {
      final _IsolateMessage data = msg[0];
      final SendPort replyTo = msg[1];

      switch (data.type) {
        case _IsolateMessageType.GET_USER_BY_ID:
          final user = await http.get('${_config.url}/user/${data.data}.json')
            .then((res) => JSON.decode(res.body))
            .then((user) => new HNUser.fromMap(user));
          replyTo.send(user);
          break;
      }

      // if (data == 'bar') port.close();
    }
  }

  Future<HNUser> getUserByID (String id) async {
    await this._init();

    addHNUser(new HNUser(id: id, computed: new HNUserComputed(loading: true)));

    final response = new ReceivePort();
    this._sendPort.send([new _IsolateMessage(
      type: _IsolateMessageType.GET_USER_BY_ID,
      data: id,
    ), response.sendPort]);

    final user = await response.first;
    addHNUser(user);
    return user;
  }
}

class _IsolateMessage {
  _IsolateMessageType type;
  dynamic data;

  _IsolateMessage ({
    @required this.type,
    @required this.data,
  });
}

enum _IsolateMessageType {
  GET_USER_BY_ID,
}
