use strict;
use warnings FATAL => 'all';
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use Test::More;

my $repo_root = abs_path(dirname(__FILE__) . "/../..");
my $hnsw_path = "$repo_root/src/hnsw.c";
my $hnsw_scan_path = "$repo_root/src/hnswscan.c";

open(my $fh, '<', $hnsw_path) or die "could not open $hnsw_path: $!";
local $/ = undef;
my $hnsw_c = <$fh>;
close($fh);

open(my $scan_fh, '<', $hnsw_scan_path) or die "could not open $hnsw_scan_path: $!";
my $hnsw_scan_c = <$scan_fh>;
close($scan_fh);

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

ok($hnsw_scan_c =~ /vector_rust_hnsw_should_return_empty_without_entrypoint_kernel\(/,
	"hnswscan.c uses rust empty-entrypoint kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_resume_from_discarded_kernel\(/,
	"hnswscan.c uses rust resume-discarded kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_return_remaining_discarded_kernel\(/,
	"hnswscan.c uses rust remaining-discarded kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_advance_on_exhausted_heaptids_kernel\(/,
	"hnswscan.c uses rust exhausted-heaptids kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_reject_missing_orderby_kernel\(/,
	"hnswscan.c uses rust missing-orderby kernel");
ok($hnsw_scan_c =~ /vector_rust_hnsw_should_reject_non_mvcc_snapshot_kernel\(/,
	"hnswscan.c uses rust non-mvcc kernel");

unlike($hnsw_scan_c, qr/return entryPointIsNull;/,
	"legacy C entrypoint-null fallback removed");
unlike($hnsw_scan_c, qr/return HnswShouldHaveNonEmptyResumeDiscardedFlag\(!discardedIsEmpty, false\);/,
	"legacy C resume-discarded fallback removed");
unlike($hnsw_scan_c, qr/return HnswShouldHaveNonEmptyRemainingDiscardedFlag\(!discardedIsEmpty, false\);/,
	"legacy C remaining-discarded fallback removed");
unlike($hnsw_scan_c, qr/return heaptidsLength == 0;/,
	"legacy C exhausted-heaptids fallback removed");
unlike($hnsw_scan_c, qr/return orderByIsNull;/,
	"legacy C missing-orderby fallback removed");
unlike($hnsw_scan_c, qr/return !snapshotIsMVCC;/,
	"legacy C non-mvcc fallback removed");
unlike($hnsw_scan_c, qr/return hasPointer;/,
	"legacy C scan-pointer fallback removed");

done_testing();
