use strict;
use warnings FATAL => 'all';
use PostgreSQL::Test::Cluster;
use PostgreSQL::Test::Utils;
use Test::More;

my $node = PostgreSQL::Test::Cluster->new('node');
$node->init;
$node->start;

$node->safe_psql("postgres", "CREATE EXTENSION vector;");
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_handler_probe() RETURNS text
	AS '$libdir/vector', 'vector_ivfflat_handler_probe'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_handler_probe() RETURNS text
	AS '$libdir/vector', 'vector_rust_ivfflat_handler_probe'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_cost_adjust(double precision, double precision, double precision, double precision, double precision, double precision) RETURNS double precision[]
	AS '$libdir/vector', 'vector_ivfflat_cost_adjust'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_cost_adjust(double precision, double precision, double precision, double precision, double precision, double precision) RETURNS double precision[]
	AS '$libdir/vector', 'vector_rust_ivfflat_cost_adjust'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_choose_insert_candidate(double precision, double precision, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_choose_insert_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_choose_insert_candidate(double precision, double precision, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_choose_insert_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_choose_scan_list_candidate(double precision, integer, integer, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_choose_scan_list_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_choose_scan_list_candidate(double precision, integer, integer, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_choose_scan_list_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_should_scan_next_list(integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_should_scan_next_list'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_should_scan_next_list(integer, integer, integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_should_scan_next_list'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_choose_build_center_candidate(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_choose_build_center_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_choose_build_center_candidate(double precision, double precision) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_choose_build_center_candidate'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_should_append_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_should_append_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_should_append_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_should_append_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_should_set_insert_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_should_set_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_should_set_insert_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_should_set_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_should_update_insert_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_should_update_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_should_update_insert_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_should_update_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_should_reuse_scan_slot(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_should_reuse_scan_slot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_should_reuse_scan_slot(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_should_reuse_scan_slot'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_scan_probe_limits(integer, integer, integer) RETURNS integer[]
	AS '$libdir/vector', 'vector_ivfflat_scan_probe_limits'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_scan_probe_limits(integer, integer, integer) RETURNS integer[]
	AS '$libdir/vector', 'vector_rust_ivfflat_scan_probe_limits'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_compute_scan_limits(integer, integer, integer, integer) RETURNS integer[]
	AS '$libdir/vector', 'vector_ivfflat_compute_scan_limits'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_compute_scan_limits(integer, integer, integer, integer) RETURNS integer[]
	AS '$libdir/vector', 'vector_rust_ivfflat_compute_scan_limits'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_should_load_more_scan_items(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_should_load_more_scan_items'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_should_load_more_scan_items(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_should_load_more_scan_items'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_probe_ratio(integer, integer) RETURNS double precision
	AS '$libdir/vector', 'vector_ivfflat_probe_ratio'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_probe_ratio(integer, integer) RETURNS double precision
	AS '$libdir/vector', 'vector_rust_ivfflat_probe_ratio'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_build_should_append_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_build_should_append_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_build_should_append_page(integer, integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_build_should_append_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_should_follow_insert_page_link(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_should_follow_insert_page_link'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_should_follow_insert_page_link(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_should_follow_insert_page_link'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_should_update_vacuum_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_should_update_vacuum_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_should_update_vacuum_insert_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_should_update_vacuum_insert_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_should_disable_without_order(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_should_disable_without_order'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_should_disable_without_order(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_should_disable_without_order'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION c_ivfflat_should_visit_scan_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_ivfflat_should_visit_scan_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});
$node->safe_psql("postgres", q{
	CREATE FUNCTION rust_ivfflat_should_visit_scan_page(integer) RETURNS boolean
	AS '$libdir/vector', 'vector_rust_ivfflat_should_visit_scan_page'
	LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
});

my $parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_handler_probe() = rust_ivfflat_handler_probe(),
		   rust_ivfflat_handler_probe() LIKE 'rust-ivfflat-handler-%';
});
is($parity, "t|t");

my $cost_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_cost_adjust(index_total_cost, num_index_pages, random_page_cost, seq_page_cost, ratio, rel_pages) =
		   rust_ivfflat_cost_adjust(index_total_cost, num_index_pages, random_page_cost, seq_page_cost, ratio, rel_pages)
	FROM (VALUES
		(100.0::double precision, 20.0::double precision, 4.0::double precision, 1.0::double precision, 0.2::double precision, 5.0::double precision),
		(250.0::double precision, 100.0::double precision, 3.5::double precision, 1.2::double precision, 0.8::double precision, 80.0::double precision),
		(50.0::double precision, 15.0::double precision, 2.5::double precision, 1.0::double precision, 0.3::double precision, 2.0::double precision)
	) AS t(index_total_cost, num_index_pages, random_page_cost, seq_page_cost, ratio, rel_pages);
});
is($cost_parity, "t\nt\nt");

my $insert_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_choose_insert_candidate(distance, min_distance, insert_page) =
		   rust_ivfflat_choose_insert_candidate(distance, min_distance, insert_page)
	FROM (VALUES
		(0.5::double precision, 1.0::double precision, 10),
		(1.5::double precision, 1.0::double precision, 10),
		(3.0::double precision, 3.0::double precision, -1),
		(2.9::double precision, 3.0::double precision, 42)
	) AS t(distance, min_distance, insert_page);
});
is($insert_candidate_parity, "t\nt\nt\nt");

my $scan_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_choose_scan_list_candidate(distance, list_count, max_probes, max_distance) =
		   rust_ivfflat_choose_scan_list_candidate(distance, list_count, max_probes, max_distance)
	FROM (VALUES
		(0.5::double precision, 0, 5, 1.0::double precision),
		(1.5::double precision, 5, 5, 2.0::double precision),
		(2.5::double precision, 5, 5, 2.0::double precision),
		(0.1::double precision, 3, 3, 0.1::double precision)
	) AS t(distance, list_count, max_probes, max_distance);
});
is($scan_candidate_parity, "t\nt\nt\nt");

my $should_scan_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_should_scan_next_list(list_index, max_probes, batch_probes, probes) =
		   rust_ivfflat_should_scan_next_list(list_index, max_probes, batch_probes, probes)
	FROM (VALUES
		(0, 10, 0, 2),
		(5, 10, 1, 2),
		(10, 10, 0, 2),
		(2, 10, 2, 2)
	) AS t(list_index, max_probes, batch_probes, probes);
});
is($should_scan_parity, "t\nt\nt\nt");

my $build_center_candidate_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_choose_build_center_candidate(distance, min_distance) =
		   rust_ivfflat_choose_build_center_candidate(distance, min_distance)
	FROM (VALUES
		(0.5::double precision, 1.0::double precision),
		(1.5::double precision, 1.0::double precision),
		(2.0::double precision, 2.0::double precision),
		(-1.0::double precision, 0.0::double precision)
	) AS t(distance, min_distance);
});
is($build_center_candidate_parity, "t\nt\nt\nt");

my $append_page_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_should_append_page(free_space, item_size) =
		   rust_ivfflat_should_append_page(free_space, item_size)
	FROM (VALUES
		(100, 101),
		(100, 100),
		(100, 99),
		(0, 1)
	) AS t(free_space, item_size);
});
is($append_page_parity, "t\nt\nt\nt");

my $set_insert_page_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_should_set_insert_page(ndeletable, insert_page) =
		   rust_ivfflat_should_set_insert_page(ndeletable, insert_page)
	FROM (VALUES
		(1, -1),
		(1, 100),
		(0, -1),
		(5, -1)
	) AS t(ndeletable, insert_page);
});
is($set_insert_page_parity, "t\nt\nt\nt");

my $update_insert_page_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_should_update_insert_page(insert_page, original_page) =
		   rust_ivfflat_should_update_insert_page(insert_page, original_page)
	FROM (VALUES
		(5, 5),
		(6, 5),
		(0, -1),
		(42, 41)
	) AS t(insert_page, original_page);
});
is($update_insert_page_parity, "t\nt\nt\nt");

my $reuse_scan_slot_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_should_reuse_scan_slot(list_count, max_probes) =
		   rust_ivfflat_should_reuse_scan_slot(list_count, max_probes)
	FROM (VALUES
		(0, 5),
		(4, 5),
		(5, 5),
		(6, 5)
	) AS t(list_count, max_probes);
});
is($reuse_scan_slot_parity, "t\nt\nt\nt");

my $scan_probe_limits_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_scan_probe_limits(probes, max_probes, lists) =
		   rust_ivfflat_scan_probe_limits(probes, max_probes, lists)
	FROM (VALUES
		(4, 8, 10),
		(12, 12, 10),
		(2, 50, 20),
		(1, 1, 1)
	) AS t(probes, max_probes, lists);
});
is($scan_probe_limits_parity, "t\nt\nt\nt");

my $compute_scan_limits_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_compute_scan_limits(probes, max_probes, lists, iterative_scan) =
		   rust_ivfflat_compute_scan_limits(probes, max_probes, lists, iterative_scan)
	FROM (VALUES
		(4, 8, 10, 0),
		(4, 8, 10, 1),
		(12, 5, 10, 0),
		(2, 50, 20, 1),
		(1, 1, 1, 1)
	) AS t(probes, max_probes, lists, iterative_scan);
});
is($compute_scan_limits_parity, "t\nt\nt\nt\nt");

my $load_more_scan_items_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_should_load_more_scan_items(list_index, max_probes) =
		   rust_ivfflat_should_load_more_scan_items(list_index, max_probes)
	FROM (VALUES
		(0, 5),
		(4, 5),
		(5, 5),
		(6, 5)
	) AS t(list_index, max_probes);
});
is($load_more_scan_items_parity, "t\nt\nt\nt");

my $probe_ratio_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_probe_ratio(probes, lists) = rust_ivfflat_probe_ratio(probes, lists)
	FROM (VALUES
		(1, 10),
		(5, 10),
		(10, 10),
		(12, 10)
	) AS t(probes, lists);
});
is($probe_ratio_parity, "t\nt\nt\nt");

my $build_append_page_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_build_should_append_page(free_space, item_size) =
		   rust_ivfflat_build_should_append_page(free_space, item_size)
	FROM (VALUES
		(100, 101),
		(100, 100),
		(100, 99),
		(0, 1)
	) AS t(free_space, item_size);
});
is($build_append_page_parity, "t\nt\nt\nt");

my $follow_insert_page_link_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_should_follow_insert_page_link(insert_page) =
		   rust_ivfflat_should_follow_insert_page_link(insert_page)
	FROM (VALUES
		(-1),
		(0),
		(1),
		(42)
	) AS t(insert_page);
});
is($follow_insert_page_link_parity, "t\nt\nt\nt");

my $vacuum_insert_page_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_should_update_vacuum_insert_page(insert_page) =
		   rust_ivfflat_should_update_vacuum_insert_page(insert_page)
	FROM (VALUES
		(-1),
		(0),
		(1),
		(42)
	) AS t(insert_page);
});
is($vacuum_insert_page_parity, "t\nt\nt\nt");

my $disable_without_order_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_should_disable_without_order(orderby_count) =
		   rust_ivfflat_should_disable_without_order(orderby_count)
	FROM (VALUES
		(0),
		(1),
		(2),
		(5)
	) AS t(orderby_count);
});
is($disable_without_order_parity, "t\nt\nt\nt");

my $visit_scan_page_parity = $node->safe_psql("postgres", q{
	SELECT c_ivfflat_should_visit_scan_page(page_no) =
		   rust_ivfflat_should_visit_scan_page(page_no)
	FROM (VALUES
		(-1),
		(0),
		(1),
		(42)
	) AS t(page_no);
});
is($visit_scan_page_parity, "t\nt\nt\nt");

done_testing();
