import 'dart:async';
import 'dart:convert' show JSON;

import 'package:http/http.dart' as http;
import 'package:flutter_flux/flutter_flux.dart';

import 'package:hn_flutter/sdk/hn_config.dart';
import 'package:hn_flutter/sdk/hn_auth_service.dart';
import 'package:hn_flutter/sdk/actions/hn_item_actions.dart';
import 'package:hn_flutter/sdk/models/hn_item.dart';
import 'package:hn_flutter/sdk/models/hn_account.dart';

class HNItemService {
  HNConfig _config = new HNConfig();
  HNAuthService _hnAuthService = new HNAuthService();

  Future<HNItem> getItemByID (int id) {
    addHNItem(new HNItemAction(new HNItem(id: id), new HNItemStatus.patch(id: id, loading: true)));

    return http.get('${this._config.url}/item/$id.json')
      .then((res) => JSON.decode(res.body))
      .then((item) => new HNItem.fromMap(item))
      .then((item) {
        addHNItem(new HNItemAction(item, new HNItemStatus.patch(id: id, loading: false)));
        return item;
      });
  }

  Future<Null> faveItem (HNItemStatus item, HNAccount account) {
    final bool save = !(item?.saved ?? false);
    toggleSaveItem(item.id);

    return http.post(
        '${this._config.apiHost}/fave',
        body: {
          'id': '${item.id}',
          'un': save ? 'f' : 't',
          'acct': account.id,
          'pw': account.password,
        },
      )
      .then((res) {
        print('FAVE RES:');
        print(res);
        print(res.body);
        if (res.body.contains('Bad login.')) {
          // undo action
          toggleSaveItem(item.id);
          throw 'Bad login.';
        } else {
          return;
        }
      });
  }

  Future<Null> voteItem (bool up, HNItemStatus status, HNAccount account) {
    if (up) {
      toggleUpvoteItem(status.id);
    } else {
      toggleDownvoteItem(status.id);
    }

    String how;
    if (up && !status.upvoted) {
      how = 'up';
    } else if (!up && !status.downvoted) {
      how = 'down';
    } else if (
      (up && status.upvoted) ||
      (!up && status.downvoted)
    ) {
      how = 'un';
    }

    return http.post(
        '${this._config.apiHost}/vote',
        body: {
          'id': '${status.id}',
          'how': how,
          'acct': account.id,
          'pw': account.password,
        },
      )
      .then((res) {
        print('VOTE RES:');
        print(res);
        print(res.body);
        if (res.body.contains('Bad login.')) {
          // undo action
          if (up) {
            toggleUpvoteItem(status.id);
          } else {
            toggleDownvoteItem(status.id);
          }
          throw 'Bad login.';
        } else {
          return;
        }
      });
  }
}
