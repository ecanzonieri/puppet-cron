# == Define: cron::d 
#
# Generates an /etc/cron.d file for you.
#
# == Reasoning
#
# Including a files makes it too easy to forget the MAILTO
# or only put 4 *s, or any other stupid mistake.
# Also, putting the cron command inline with the puppet code to generate
# it generally involves less tail chasing when you're looking for a job
#
# == Examples
#
# This makes a job which runs every min, and emails systems+cron@yelp.com
# if anything is sent to stdout
#
# ```
# cron::d { 'minimum_example':
#     minute  => '*',
#     user    => 'push',
#     command     => '/nail/sys/bin/example_job | logger'
#  }
#  ```
#
# Full example with all optional params:
# ```
# cron::d { 'name_of_cronjob':
#     minute  => '*',
#     hour    => '*',
#     dom     => '*',
#     month   => '*',
#     dow     => '*',
#     user    => 'bob',
#     mailto  => 'example@yelp.com',
#     command     => '/some/example/job';
# }
# ```
#
# == Parameters
#
# [*lock*]
# Boolean that defaults to false. If true, the command will be wrapped in a
# a `flock` invocation to prevent the cron job from stacking.
#
define cron::d (
  $minute,
  $command,
  $user,
  $hour='*',
  $dom='*',
  $month='*',
  $dow='*',
  $mailto='""',
  $log_to_syslog=true,
  $staleness_threshold=undef,
  $staleness_check_params=undef,
  $annotation=annotate(),
  $lock=false,
  $comment='',
) {
  # Deliberate copy here so we can add extra fancy options (like pipe stdout
  # to scribe) in additional parameters later
  validate_cron_numeric($minute)
  validate_cron_numeric($hour)
  validate_cron_numeric($dom)
  validate_cron_numeric($month)
  validate_cron_numeric($dow)

  validate_bool($log_to_syslog,$lock)

  include cron

  $reporting_name = "cron_${name}"

  if $staleness_threshold {
    $actual_command = "/nail/sys/bin/success_wrapper '${reporting_name}' ${command}"

    cron::staleness_check { $reporting_name:
      threshold  => $staleness_threshold,
      params     => $staleness_check_params,
      user       => $user,
      annotation => $annotation,
    }
  } else {
    $actual_command = $command
  }

  # If both syslogging and mailing are requested, choose mailing over syslogging
  $actually_log_to_syslog = $log_to_syslog and $mailto=='""'

  cron::file { $name:
    file_params => {
      content => template('cron/d.erb'),
    },
  }
}
