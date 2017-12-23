# Emacs' sieve-manage is a delight.
# Alternatively, use sieve-connect:
# sieve-connect --upload --localsieve filters.sieve -s m***r.i***a.i****s.ru -u <user> [--notlsverify]
# Don't forget to activate your sieve script.

require ["copy","fileinto"];

if header :contains "Delivered-To" "gcc-patches@gcc.gnu.org" {
  fileinto "gcc-patches";
}

if header :matches "X-KLMS-AntiSpam-Status" "spam" {
  fileinto "Junk";
}

# rule:[fwd-compilers]
if header :contains "from" "moodle.cloud.unihub"
{
	redirect :copy "bmk-compilers@ispras.ru";
}
