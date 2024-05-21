-- Create an appendonly columnar distribut replicated table to make the citd increase control easier. 
-- Insert 60921 rows into segment1. The row count is very exactly to trigger the bug. As we need to 
-- hit three conner cases: 
-- 1. GIN index posting list must put the first tuple of a new aoco segment at the end to one list segment.
-- for example: encoded delta value is [1,2,10000]. 10000 is the delta of first tuple of the new segment ctid.
-- 2. For a GinPostingListSegmentTargetSize(256) length segment, we need to make sure the left space for the
-- first tuple of the new segment is 6 bytes. Can not be less or more. So it can reach the memory overflow.
-- 3. Next time palloc must do the real malloc. not choose a free space from the memory context. This means
-- we need to consume all the free space in the memory context before we reach the point in step.1.
-- Above the three conner cases must be hit. So we need to control the inserted rows.
-- Make some dead segment by abort transaction, to make a big jump of ctid.

CREATE TABLE test_gin_aoco(a int, org_name varchar(20)) with (appendonly = true, orientation = column) distributed replicated;

1: begin;
1: insert into test_gin_aoco select i, 'test' from generate_series(1,60921) i;
2: begin;
2: insert into test_gin_aoco select i, 'test' from generate_series(1,100) i;
3: begin;
3: insert into test_gin_aoco select i, 'test' from generate_series(1,100) i;
4: begin;
4: insert into test_gin_aoco select i, 'test' from generate_series(1,100) i;
5: begin;
5: insert into test_gin_aoco select i, 'test' from generate_series(1,100) i;
6: begin;
6: insert into test_gin_aoco select i, 'test' from generate_series(1,100) i;
7: begin;
7: insert into test_gin_aoco select i, 'test' from generate_series(1,100) i;
8: begin;
8: insert into test_gin_aoco select i, 'test' from generate_series(1,100) i;
9: begin;
9: insert into test_gin_aoco select i, 'test' from generate_series(1,100) i;
10: begin;
10: insert into test_gin_aoco select i, 'test' from generate_series(1,4189) i;

1: commit;
2: abort;
3: abort;
4: abort;
5: abort;
6: abort;
7: abort;
8: abort;
9: abort;
10: commit;

1q:
2q:
3q:
4q:
5q:
6q:
7q:
8q:
9q:
10q:

-- Create GIN Index to hit the bug.
CREATE INDEX test_gin_aoco_to_tsvector_idx ON test_gin_aoco USING gin (to_tsvector('english', (org_name)::text));

-- Clear
DROP TABLE test_gin_aoco;