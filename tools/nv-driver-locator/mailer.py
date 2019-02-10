#!/usr/bin/env python3

import smtplib
import ssl


class Mailer:
    def __init__(self, *,
                 from_addr,
                 host='localhost',
                 port=None,
                 local_hostname=None,
                 use_ssl=False,
                 use_starttls=False,
                 login=None,
                 password=None,
                 timeout=10):
        if use_ssl or use_starttls:
            self._ssl_context = ssl.create_default_context()
        self._from_addr = from_addr
        self._host = host
        self._local_hostname = local_hostname
        self._use_ssl = use_ssl
        self._use_starttls = use_starttls
        self._login = login
        self._password = password
        self._timeout = timeout
        if port is None:
            if use_ssl:
                self._port = 465
            elif use_starttls:
                self._port = 587
            else:
                self._port = 25
        else:
            self._port = port

    def send(self, to, msg, mail_options=(), rcpt_options=()):
        if not self._use_ssl:
            server = smtplib.SMTP(self._host, self._port, self._local_hostname,
                                  self._timeout)
        else:
            server = smtplib.SMTP_SSL(self._host, self._port,
                                      self._local_hostname,
                                      timeout=self._timeout,
                                      context=self._ssl_context)

        with server:
            if self._use_starttls and not self._use_ssl:
                server.starttls(context=self._ssl_context)
            if self._login is not None:
                server.login(self._login, self._password)
            server.sendmail(self._from_addr, to, msg,
                            mail_options, rcpt_options)


def parse_args():
    import argparse

    def check_positive_float(val):
        val = float(val)
        if val <= 0:
            raise ValueError("Value %s is not valid positive float" %
                             (repr(val),))
        return val

    def check_port(val):
        val = int(val)
        if not (0 < val <= 0xFFFF):
            raise ValueError("Value %s is not valid port number" %
                             (repr(val),))
        return val

    parser = argparse.ArgumentParser(
        description="Simple email sender, suitable for modern email services.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-f", "--from",
                        required=True,
                        dest="from_address",
                        help="originating address")
    parser.add_argument("-H", "--smtp-host",
                        default='localhost',
                        help="hostname of local MTA or external SMTP service")
    parser.add_argument("-P", "--smtp-port",
                        type=check_port,
                        help="SMTP port. "
                        "Default value depends on SSL/TLS mode")
    parser.add_argument("-L", "--local-hostname",
                        help="hostname to use in EHLO/HELO commands. "
                        "Defaults to autodiscover of local host name.")
    tls_group = parser.add_mutually_exclusive_group()
    tls_group.add_argument("-S", "--ssl",
                           help="use SSL from beginning of connection",
                           action="store_true")
    tls_group.add_argument("-s", "--starttls",
                           help="use STARTTLS command for secure connection",
                           action="store_true")
    parser.add_argument("-l", "--login",
                        help="user login name. "
                        "If omitted, no login performed.")
    parser.add_argument("-p", "--password",
                        help="user password used for login")
    parser.add_argument("-T", "--timeout",
                        type=check_positive_float,
                        default=10.,
                        help="timeout for network operations")
    parser.add_argument("-j", "--subject",
                        default="",
                        help="email subject")
    parser.add_argument("-m", "--message",
                        help="email message body. If not specified, message "
                        "will be read from stdin")
    parser.add_argument("recipient",
                        nargs="+",
                        help="email destination address(es)")

    args = parser.parse_args()
    return args


def main():
    import sys
    from email.mime.text import MIMEText

    args = parse_args()
    m = Mailer(from_addr=args.from_address,
               host=args.smtp_host,
               port=args.smtp_port,
               local_hostname=args.local_hostname,
               use_ssl=args.ssl,
               use_starttls=args.starttls,
               login=args.login,
               password=args.password,
               timeout=args.timeout)
    if args.message is None:
        print("Reading message from standard input...", file=sys.stderr)
        msg = sys.stdin.read()
    else:
        msg = args.message

    msg = MIMEText(msg)
    msg['Subject'] = args.subject
    msg['From'] = args.from_address
    msg['To'] = ', '.join(args.recipient)
    m.send(args.recipient, msg.as_string())


if __name__ == '__main__':
    main()
