add jar /opt/hivemall/target/hivemall-xgboost-0.60-0.4.2-rc.2-with-dependencies.jar;
source /opt/hivemall/resources/ddl/define-additional.hive;

set hivevar:f0_min=4.3;
set hivevar:f0_max=7.9;
set hivevar:f1_min=2.0;
set hivevar:f1_max=4.4;
set hivevar:f2_min=1.0;
set hivevar:f2_max=6.9;
set hivevar:f3_min=0.1;
set hivevar:f3_max=2.5;

use iris;
create or replace view iris_scaled
as
select
  rowid, 
  label,
  add_bias(array(
     concat("1:", rescale(features[0],${hivevar:f0_min},${hivevar:f0_max})), 
     concat("2:", rescale(features[1],${hivevar:f1_min},${hivevar:f1_max})), 
     concat("3:", rescale(features[2],${hivevar:f2_min},${hivevar:f2_max})), 
     concat("4:", rescale(features[3],${hivevar:f3_min},${hivevar:f3_max}))
  )) as features
from 
  iris_raw;

-- select * from iris_scaled limit 3;
-- 1       Iris-setosa     ["1:0.22222215","2:0.625","3:0.0677966","4:0.041666664","0:1.0"]
-- 2       Iris-setosa     ["1:0.16666664","2:0.41666666","3:0.0677966","4:0.041666664","0:1.0"]
-- 3       Iris-setosa     ["1:0.11111101","2:0.5","3:0.05084745","4:0.041666664","0:1.0"]

select train_xgboost_classifier(features, case when label = 'Iris-setosa' then 1.0 else 0.0 end) from iris_scaled;
