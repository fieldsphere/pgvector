use strict;
use warnings FATAL => 'all';
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Test::More;

my $repo_root = abs_path(dirname(__FILE__) . "/../..");
my $hnsw_path = "$repo_root/src/hnsw.c";

open(my $fh, '<', $hnsw_path) or die "could not open $hnsw_path: $!";
local $/ = undef;
my $hnsw_c = <$fh>;
close($fh);

ok($hnsw_c =~ /vector_rust_hnsw_should_disable_without_order_kernel\(/,
	"hnsw.c uses rust disable-without-order kernel");
ok($hnsw_c =~ /vector_rust_hnsw_clamp_ratio_kernel\(/,
	"hnsw.c uses rust clamp-ratio kernel");
ok($hnsw_c =~ /vector_rust_hnsw_should_adjust_startup_cost_kernel\(/,
	"hnsw.c uses rust startup-cost kernel");
ok($hnsw_c =~ /vector_rust_hnsw_should_compute_scan_ratio_from_tuples_kernel\(/,
	"hnsw.c uses rust scan-ratio kernel");

unlike($hnsw_c, qr/return !preloadInProgress;/,
	"legacy C preload lock-tranche fallback removed");
unlike($hnsw_c, qr/return !found;/,
	"legacy C lock-tranche assignment fallback removed");
unlike($hnsw_c, qr/return orderbyCount == 0;/,
	"legacy C disable-without-order fallback removed");
unlike($hnsw_c, qr/return ratio > 1;/,
	"legacy C cap-ratio fallback removed");
unlike($hnsw_c, qr/return startupPages > relPages && ratio < 0.5;/,
	"legacy C startup-cost fallback removed");
unlike($hnsw_c, qr/return tupleCount > 0;/,
	"legacy C scan-ratio fallback removed");

done_testing();
