# == Define: elasticsearch::template
#
#  This define allows you to insert, update or delete Elasticsearch index
#  templates.
#
#  Template content should be defined through either the `content` parameter
#  (when passing a hash or json string) or the `source` parameter (when passing
#  the puppet file URI to a template json file).
#
# === Parameters
#
# [*ensure*]
#   Controls whether the named index template should be present or absent in
#   the cluster.
#   Value type is string
#   Default value: present
#
# [*source*]
#   Source path for the template file. Can be any value similar to `source`
#   values for `file` resources.
#   Value type is string
#   Default value: undef
#   This variable is optional
#
# [*content*]
#   Contents of the template. Can be either a puppet hash or a string
#   containing JSON.
#   Value type is string or hash.
#   Default value: undef
#   This variable is optional
#
# [*api_protocol*]
#   Protocol that should be used to connect to the Elasticsearch API.
#   Value type is string
#   Default value inherited from elasticsearch::api_protocol: http
#   This variable is optional
#
# [*api_host*]
#   Host name or IP address of the ES instance to connect to
#   Value type is string
#   Default value inherited from $elasticsearch::api_host: localhost
#   This variable is optional
#
# [*api_port*]
#   Port number of the ES instance to connect to
#   Value type is number
#   Default value inherited from $elasticsearch::api_port: 9200
#   This variable is optional
#
# [*api_timeout*]
#   Timeout period (in seconds) for the Elasticsearch API.
#   Value type is int
#   Default value inherited from elasticsearch::api_timeout: 10
#   This variable is optional
#
# [*api_basic_auth_username*]
#   HTTP basic auth username to use when communicating over the Elasticsearch
#   API.
#   Value type is String
#   Default value inherited from elasticsearch::api_basic_auth_username: undef
#   This variable is optional
#
# [*api_basic_auth_password*]
#   HTTP basic auth password to use when communicating over the Elasticsearch
#   API.
#   Value type is String
#   Default value inherited from elasticsearch::api_basic_auth_password: undef
#   This variable is optional
#
# [*api_ca_file*]
#   Path to a CA file which will be used to validate server certs when
#   communicating with the Elasticsearch API over HTTPS.
#   Value type is String
#   Default value inherited from elasticsearch::api_ca_file: undef
#   This variable is optional
#
# [*api_ca_path*]
#   Path to a directory with CA files which will be used to validate server
#   certs when communicating with the Elasticsearch API over HTTPS.
#   Value type is String
#   Default value inherited from elasticsearch::api_ca_path: undef
#   This variable is optional
#
# [*validate_tls*]
#   Determines whether the validity of SSL/TLS certificates received from the
#   Elasticsearch API should be verified or ignored.
#   Value type is boolean
#   Default value inherited from elasticsearch::validate_tls: true
#   This variable is optional
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard.pijnenburg@elasticsearch.com>
# * Tyler Langlois <mailto:tyler@elastic.co>
#
define elasticsearch::template (
  $ensure                  = 'present',
  $source                  = undef,
  $content                 = undef,
  $api_protocol            = $elasticsearch::api_protocol,
  $api_host                = $elasticsearch::api_host,
  $api_port                = $elasticsearch::api_port,
  $api_timeout             = $elasticsearch::api_timeout,
  $api_basic_auth_username = $elasticsearch::api_basic_auth_username,
  $api_basic_auth_password = $elasticsearch::api_basic_auth_password,
  $api_ca_file             = $elasticsearch::api_ca_file,
  $api_ca_path             = $elasticsearch::api_ca_path,
  $validate_tls            = $elasticsearch::validate_tls,
) {
  validate_string(
    $api_protocol,
    $api_host,
    $api_basic_auth_username,
    $api_basic_auth_password
  )
  validate_bool($validate_tls)

  if ! ($ensure in ['present', 'absent']) {
    fail("'${ensure}' is not a valid 'ensure' parameter value")
  }
  if ! is_integer($api_port)    { fail('"api_port" is not an integer') }
  if ! is_integer($api_timeout) { fail('"api_timeout" is not an integer') }
  if ($api_ca_file != undef) { validate_absolute_path($api_ca_file) }
  if ($api_ca_path != undef) { validate_absolute_path($api_ca_path) }

  if $source != undef { validate_string($source) }

  if $content != undef and is_string($content) {
    $_content = parsejson($content)
  } else {
    $_content = $content
  }

  if $ensure == 'present' and $source == undef and $_content == undef {
    fail('one of "file" or "content" required.')
  } elsif $source != undef and $_content != undef {
    fail('"file" and "content" cannot be simultaneously defined.')
  }

  require elasticsearch

  es_instance_conn_validator { "${name}-template":
    server => $api_host,
    port   => $api_port,
  } ->
  elasticsearch_template { $name:
    ensure       => $ensure,
    content      => $_content,
    source       => $source,
    protocol     => $api_protocol,
    host         => $api_host,
    port         => $api_port,
    timeout      => $api_timeout,
    username     => $api_basic_auth_username,
    password     => $api_basic_auth_password,
    ca_file      => $api_ca_file,
    ca_path      => $api_ca_path,
    validate_tls => $validate_tls,
  }
}
