import '../Constants.dart' as DartSIP_C;
import '../logger.dart';

class C {
  static final event_type = 'refer';
  static final body_type = 'message/sipfrag;version=2.0';
  static final expires = 300;
}

class ReferNotifier {
  var _session;
  var _id;
  var _expires;
  var _active;
  final logger = Logger('RTCSession:ReferNotifier');
  debug(msg) => logger.debug(msg);
  debugerror(error) => logger.error(error);

  ReferNotifier(session, id, [expires]) {
    this._session = session;
    this._id = id;
    this._expires = expires ?? C.expires;
    this._active = true;

    // The creation of a Notifier results in an immediate NOTIFY.
    this.notify(100);
  }

  notify(code, [reason]) {
    debug('notify()');

    if (this._active == false) {
      return;
    }

    reason = reason ?? DartSIP_C.REASON_PHRASE[code] ?? '';

    var state;

    if (code >= 200) {
      state = 'terminated;reason=noresource';
    } else {
      state = 'active;expires=${this._expires}';
    }

    // Put this in a try/catch block.
    this._session.sendRequest(DartSIP_C.NOTIFY, {
      'extraHeaders': [
        'Event: ${C.event_type};id=${this._id}',
        'Subscription-State: ${state}',
        'Content-Type: ${C.body_type}'
      ],
      'body': 'SIP/2.0 ${code} ${reason}',
      'eventHandlers': {
        // If a negative response is received, subscription is canceled.
        'onErrorResponse': () {
          this._active = false;
        }
      }
    });
  }
}