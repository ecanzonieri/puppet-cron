require 'spec_helper'

describe 'cron' do

  context 'by default' do
   let(:facts) {{
     :operatingsystemrelease => '14.04'
   }}
   it { should compile }
   it { should contain_file('/nail/sys/bin/cron_staleness_check') }
  end

end
