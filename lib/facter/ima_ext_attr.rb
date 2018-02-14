# A strucured fact to tell if the file system appears to
# be label with security.ima extended attributes.
#
# This will check a common executable file for securty.ima attributes
#
# return values:
#
# true if it is label
# false if it is not labled
#
Facter.add('ima_ext_attr') do
  confine do
    Facter::Core::Execution.which('getfattr')
  end

  setcode do

  # Check if the script to update the attributes is still running
    isrunning = Facter::Util::Resolution.exec('ps -ef')
    if isrunning['ima_security_attr_update.sh'].nil?
      #  This command is removed and then recreated when ima_appraise is
      #  changed to fix so that the hashes are recreated.
      cmd = '/usr/local/bin/ima_security_attr_update.sh'
      if File.exists?("#{cmd}")
        attributes = Facter::Util::Resolution.exec("getfattr -m ima -d #{cmd}")
        if attributes['security.ima='].nil?
          status = 'not_set'
        else
          status = 'set'
        end
      else
        status = 'unknown'
      end
    else
      status = 'updating'
    end

    status
  end
end
