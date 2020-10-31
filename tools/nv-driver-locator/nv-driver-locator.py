#!/usr/bin/env python3

import sys
import json
import argparse
import hashlib
import importlib
import logging
from abc import ABC, abstractmethod
import functools


HASH_DELIM = b'\x00'
HASH = hashlib.sha256


class BaseDB(ABC):
    @abstractmethod
    def check_key(self, key):
        pass

    @abstractmethod
    def set_key(self, key, value):
        pass


class FileDB(BaseDB):
    def __init__(self, workdir):
        self._ospath = importlib.import_module('os.path')
        self._tempfile = importlib.import_module('tempfile')
        self._wd = workdir
        self._test_writable()

    def _test_writable(self):
        TEST_STRING = b"test"
        with self._tempfile.NamedTemporaryFile('w+b', 0, dir=self._wd) as f:
            f.write(TEST_STRING)
            f.flush()
            with open(f.name, 'rb') as tf:
                assert tf.read() == TEST_STRING, "Test write failed"

    def _get_key_filename(self, key):
        return self._ospath.join(self._wd, key + '.json')

    def check_key(self, key):
        filename = self._get_key_filename(key)
        return self._ospath.isfile(filename)

    def set_key(self, key, obj):
        filename = self._get_key_filename(key)
        with open(filename, 'w') as f:
            json.dump(obj, f, indent=4)
            f.flush()


class Hasher:
    def __init__(self, key_components):
        self._key_components = key_components

    def _eval_key_component(self, obj, component_path):
        res = obj
        try:
            for path_component in component_path:
                res = res[path_component]
        except (KeyError, IndexError):
            return b''
        return str(res).encode('utf-8')

    def hash_object(self, obj):
        return HASH(HASH_DELIM.join(
            self._eval_key_component(obj, c) for c in self._key_components)
        ).hexdigest()


class BaseNotifier(ABC):
    @abstractmethod
    def notify(self, obj):
        pass


class EmailNotifier(BaseNotifier):
    def __init__(self, name, *,
                 from_addr,
                 to_addrs,
                 host='localhost',
                 port=None,
                 local_hostname=None,
                 use_ssl=False,
                 use_starttls=False,
                 login=None,
                 password=None,
                 timeout=10):
        self.name = name
        self._from_addr = from_addr
        self._Mailer = importlib.import_module('mailer').Mailer
        self._MIMEText = importlib.import_module('email.mime.text').MIMEText
        self._MIMEMult = importlib.import_module(
            'email.mime.multipart').MIMEMultipart
        self._MIMEBase = importlib.import_module('email.mime.base').MIMEBase
        self._encoders = importlib.import_module('email.encoders')
        self._mimeheader = importlib.import_module('email.header').Header
        self._m = self._Mailer(from_addr=from_addr,
                               host=host,
                               port=port,
                               local_hostname=local_hostname,
                               use_ssl=use_ssl,
                               use_starttls=use_starttls,
                               login=login,
                               password=password,
                               timeout=timeout)
        self._to_addrs = to_addrs

    def notify(self, obj):
        msg = self._MIMEMult()
        msg['Subject'] = self._mimeheader("New Nvidia driver available!", "utf-8")
        msg['From'] = self._from_addr
        msg['To'] = ', '.join(self._to_addrs)
        obj_text = json.dumps(obj, indent=4, ensure_ascii=False)
        msg_text = json.dumps(obj, indent=4, ensure_ascii=True)
        body = "See attached JSON or message body below:\n"
        body += msg_text
        msg.attach(self._MIMEText(body, 'plain', 'utf-8'))
        p = self._MIMEBase('application', 'octet-stream')
        p.set_payload(obj_text.encode('ascii'))
        self._encoders.encode_base64(p)
        p.add_header('Content-Disposition', "attachment; filename=obj.json")
        msg.attach(p)
        self._m.send(self._to_addrs, msg.as_string())


class CommandNotifier(BaseNotifier):
    def __init__(self, name, *,
                 cmdline,
                 timeout=10):
        self.name = name
        self._subprocess = importlib.import_module('subprocess')
        self._cmdline = cmdline
        self._timeout = timeout

    def notify(self, obj):
        proc = self._subprocess.Popen(self._cmdline,
                                      stdin=self._subprocess.PIPE)
        try:
            proc.communicate(json.dumps(obj, indent=4).encode('utf-8'),
                             self._timeout)
        except self._subprocess.TimeoutExpired:
            proc.kill()
            proc.communicate()


class BaseChannel(ABC):
    @abstractmethod
    def get_latest_drivers(self):
        pass


class GFEClientChannel(BaseChannel):
    def __init__(self, name, notebook=False,
                             x86_64=True,
                             os_version="10.0",
                             os_build="17763",
                             language=1033,
                             beta=False,
                             dch=False,
                             crd=False,
                             timeout=10):
        self.name = name
        self._notebook = notebook
        self._x86_64 = x86_64
        self._os_version = os_version
        self._os_build = os_build
        self._language = language
        self._beta = beta
        self._dch = dch
        self._crd = crd
        self._timeout = timeout
        gfe_get_driver = importlib.import_module('gfe_get_driver')
        self._get_latest_drivers = gfe_get_driver.get_latest_geforce_driver

    def get_latest_drivers(self):
        res = self._get_latest_drivers(notebook=self._notebook,
                                       x86_64=self._x86_64,
                                       os_version=self._os_version,
                                       os_build=self._os_build,
                                       language=self._language,
                                       beta=self._beta,
                                       dch=self._dch,
                                       crd=self._crd,
                                       timeout=self._timeout)
        if res is None:
            return
        res.update({
            'ChannelAttributes': {
                'Name': self.name,
                'Type': self.__class__.__name__,
                'OS': 'Windows%d_%d' % (float(self._os_version),
                                        64 if self._x86_64 else 32),
                'OSBuild': self._os_build,
                'Language': self._language,
                'Beta': self._beta,
                'DCH': self._dch,
                'CRD': self._crd,
                'Mobile': self._notebook,
            }
        })
        yield res


class NvidiaDownloadsChannel(BaseChannel):
    def __init__(self, name, *,
                 os="Linux_64",
                 product="GeForce",
                 certlevel="All",
                 driver_type="Standard",
                 lang="English",
                 cuda_ver="Nothing",
                 timeout=10):
        self.name = name
        gnd = importlib.import_module('get_nvidia_downloads')
        self._gnd = gnd
        self._os = gnd.OS[os]
        self._product = gnd.Product[product]
        self._certlevel = gnd.CertLevel[certlevel]
        self._driver_type = gnd.DriverType[driver_type]
        self._lang = gnd.DriverLanguage[lang]
        self._cuda_ver = gnd.CUDAToolkitVersion[cuda_ver]
        self._timeout = timeout

    def get_latest_drivers(self):
        latest = self._gnd.get_drivers(os=self._os,
                                       product=self._product,
                                       certlevel=self._certlevel,
                                       driver_type=self._driver_type,
                                       lang=self._lang,
                                       cuda_ver=self._cuda_ver,
                                       timeout=self._timeout)
        if not latest:
            return
        res = {
            'DriverAttributes': {
                'Version': latest['version'],
                'Name': latest['name'],
                'NameLocalized': latest['name'],
            },
            'ChannelAttributes': {
                'Name': self.name,
                'Type': self.__class__.__name__,
                'OS': self._os.name,
                'Product': self._product.name,
                'CertLevel': self._certlevel.name,
                'DriverType': self._driver_type.name,
                'Lang': self._lang.name,
                'CudaVer': self._cuda_ver.name,
            }
        }
        if 'download_url' in latest:
            res['DriverAttributes']['DownloadURL'] = latest['download_url']
        yield res


class CudaToolkitDownloadsChannel(BaseChannel):
    def __init__(self, name, *,
                 timeout=10):
        self.name = name
        gcd = importlib.import_module('get_cuda_downloads')
        self._gcd = gcd
        self._timeout = timeout

    def get_latest_drivers(self):
        latest = self._gcd.get_latest_cuda_tk(timeout=self._timeout)
        if not latest:
            return
        yield {
            'DriverAttributes': {
                'Version': '???',
                'Name': latest,
                'NameLocalized': latest,
            },
            'ChannelAttributes': {
                'Name': self.name,
                'Type': self.__class__.__name__,
            }
        }

class VulkanBetaDownloadsChannel(BaseChannel):
    def __init__(self, name, *,
                 timeout=10):
        self.name = name
        self._timeout = timeout
        self._gvd = importlib.import_module('get_vulkan_downloads')

    def get_latest_drivers(self):
        drivers = self._gvd.get_drivers(timeout=self._timeout)
        if drivers is None:
            return
        for drv in drivers:
            yield {
                'DriverAttributes': {
                    'Version': drv['version'],
                    'Name': drv['name'],
                    'NameLocalized': drv['name'],
                },
                'ChannelAttributes': {
                    'Name': self.name,
                    'Type': self.__class__.__name__,
                    'OS': drv['os'],
                }
            }

class DebRepoChannel(BaseChannel):
    def __init__(self, name, *,
                 url,
                 pkg_pattern,
                 driver_name="Linux x64 (AMD64/EM64T) Display Driver",
                 timeout=10):
        self.name = name
        self._gdd = importlib.import_module('get_deb_drivers')
        self._url = url
        self._pkg_pattern = pkg_pattern
        self._driver_name = driver_name
        self._timeout = timeout

    def get_latest_drivers(self):
        drivers = self._gdd.get_deb_versions(url=self._url,
                                             name=self._pkg_pattern,
                                             timeout=self._timeout)
        if drivers is None:
            return
        for drv in drivers:
            yield {
                'DriverAttributes': {
                    'Version': drv.version,
                    'DebPkgName': drv.name,
                    'Name': self._driver_name,
                    'NameLocalized': self._driver_name,
                },
                'ChannelAttributes': {
                    'Name': self.name,
                    'Type': self.__class__.__name__,
                    'OS': 'Linux_64',
                    'PkgPattern': self._pkg_pattern,
                }
            }

def parse_args():
    parser = argparse.ArgumentParser(
        description="Watches for GeForce experience driver updates for "
        "configured systems",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("-c", "--config",
                        default="/etc/nv-driver-locator.json",
                        help="config file location")
    args = parser.parse_args()
    return args


class DriverLocator:
    _ret_code = 0

    def __init__(self, conf):
        self._logger = logging.getLogger(self.__class__.__name__)
        self._channels = self._construct_channels(conf['channels'])
        self._db = self._construct_db(conf['db'])
        self._hasher = Hasher(conf['key_components'])
        self._notifiers = self._construct_notifiers(conf['notifiers'])

    def _construct_channels(self, channels_config):
        channel_types = {
            'gfe_client': GFEClientChannel,
            'nvidia_downloads': NvidiaDownloadsChannel,
            'cuda_downloads': CudaToolkitDownloadsChannel,
            'vulkan_beta': VulkanBetaDownloadsChannel,
            'deb_packages': DebRepoChannel,
        }

        channels = []
        for ch in channels_config:
            try:
                ctor = channel_types[ch['type']]
                C = ctor(ch['name'], **ch['params'])
            except Exception as e:
                self._perror("Channel construction failed with exception: %s. "
                             "Skipping..." % (str(e),))
            else:
                channels.append(C)
        return channels

    def _construct_db(self, db_config):
        db_types = {
            'file': FileDB,
        }
        ctor = db_types[db_config['type']]
        db = ctor(**db_config['params'])
        return db

    def _construct_notifiers(self, notifiers_config):
        notifier_types = {
            'email': EmailNotifier,
            'command': CommandNotifier,
        }

        notifiers = []
        for nc in notifiers_config:
            try:
                ctor = notifier_types[nc['type']]
                N = ctor(nc['name'], **nc['params'])
            except Exception as e:
                self._perror("Notifier construction failed with exception: %s."
                             " Skipping..." % (str(e),))
            else:
                notifiers.append(N)
        return notifiers

    def _perror(self, err):
        self._ret_code = 3
        self._logger.error(err)

    def _notify_all(self, obj):
        fails = 0
        for n in self._notifiers:
            try:
                n.notify(obj)
            except Exception as e:
                self._perror("Notify channel %s failed with exception: %s." %
                             (n.name, str(e)))
                fails += 1
        return fails < len(self._notifiers)

    def run(self):
        for ch in self._channels:
            counter = 0
            try:
                drivers = ch.get_latest_drivers()
            except Exception as e:
                self._perror("get_latest_drivers() invocation failed for "
                             "channel %s. Exception: %s. Continuing..." %
                             (repr(ch.name), str(e)))
                continue

            try:
                # Fetch
                for drv in drivers:
                    counter += 1
                    # Hash
                    try:
                        key = self._hasher.hash_object(drv)
                    except Exception as e:
                        self._perror("Key evaluation failed for channel %s. "
                                     "Exception: %s" % (repr(name), str(e)))
                        continue

                    # Notify
                    if not self._db.check_key(key):
                        if self._notify_all(drv):
                            self._db.set_key(key, drv)
            except Exception as e:
                self._perror("channel %s enumeration terminated with exception: %s" %
                             (repr(name), str(e)))
                continue

            if not counter:
                self._perror("Drivers not found for channel %s" %
                             (repr(ch.name),))
        return self._ret_code


def setup_logger(name, verbosity):
    logger = logging.getLogger(name)
    logger.setLevel(verbosity)
    handler = logging.StreamHandler()
    handler.setLevel(verbosity)
    handler.setFormatter(logging.Formatter('%(asctime)s '
                                           '%(levelname)-8s '
                                           '%(name)s: %(message)s',
                                           '%Y-%m-%d %H:%M:%S'))
    logger.addHandler(handler)
    return logger


def main():
    args = parse_args()
    setup_logger(DriverLocator.__name__, logging.ERROR)

    with open(args.config, 'r') as conf_file:
        conf = json.load(conf_file)

    ret = DriverLocator(conf).run()
    sys.exit(ret)


if __name__ == '__main__':
    main()
