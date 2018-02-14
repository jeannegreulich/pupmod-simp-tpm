require 'spec_helper'

describe 'ima_ext_attr', :type => :fact do

  before :each do
    Facter.clear
    Facter.clear_messages
    Facter::Core::Execution.stubs(:which).with('getfattr').returns(true)
  end

  context 'The script is running' do
    before(:each) { Facter::Util::Resolution.stubs(:exec).with('ps -ef').returns 'All kinds of junk and ima_security_attr_update.sh'}

    it 'should return updating' do
      expect(Facter.fact(:ima_ext_attr).value).to eq 'updating'
    end
  end

  context 'The script is not running' do
    before(:each) { Facter::Util::Resolution.stubs(:exec).with('ps -ef').returns 'All kinds of junki\nAnd more junk\nbut not that which shall not be named'}

    context 'The script is not present' do
      before(:each) { File.stubs(:exists?).with('/usr/local/bin/ima_security_attr_update.sh').returns(false) }

      it 'should return unknown' do
        expect(Facter.fact(:ima_ext_attr).value).to eq 'unknown'
      end
    end

    context 'The script is present' do
      before(:each) { File.stubs(:exists?).with('/usr/local/bin/ima_security_attr_update.sh').returns(true) }

      context 'Security.ima attribute is set' do
        before(:each) { Facter::Util::Resolution.stubs(:exec).with("getfattr -m ima -d /usr/local/bin/ima_security_attr_update.sh").returns '#stuff\nsecurity.ima=myfavoritehash' }

        it 'should return set' do
          expect(Facter.fact(:ima_ext_attr).value).to eq 'set'
        end
      end

      context 'Security.ima attribute is not set' do
        before(:each) { Facter::Util::Resolution.stubs(:exec).with("getfattr -m ima -d /usr/local/bin/ima_security_attr_update.sh").returns '#more stuff that shall not be named' }

        it 'should return not_set' do
          expect(Facter.fact(:ima_ext_attr).value).to eq 'not_set'
        end
      end
    end
  end
end
