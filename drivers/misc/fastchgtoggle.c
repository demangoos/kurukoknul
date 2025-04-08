#include <linux/module.h>
 #include <linux/kobject.h>
 #include <linux/sysfs.h>
 #include <linux/power_supply.h>
 #include <misc/fastchgtoggle.h>
 
 int fast_chg_enabled = FAST_CHARGE_ENABLED;
 
 bool fast_chg_allowed(void)
 {
     return fast_chg_enabled;
 }
 
 static ssize_t enabled_show(struct kobject *kobj, 
                           struct kobj_attribute *attr, 
                           char *buf)
 {
     return sprintf(buf, "%d\n", fast_chg_enabled);
 }
 
 static ssize_t enabled_store(struct kobject *kobj,
                            struct kobj_attribute *attr,
                            const char *buf, 
                            size_t count)
 {
     int ret, val;
     
     ret = kstrtoint(buf, 10, &val);
     if (ret < 0)
         return ret;
 
     if (val == FAST_CHARGE_DISABLED || val == FAST_CHARGE_ENABLED)
         fast_chg_enabled = val;
     
     return count;
 }
 
 static struct kobj_attribute enabled_attr = 
     __ATTR(enabled, 0664, enabled_show, enabled_store);
 
 static struct attribute *attrs[] = {
     &enabled_attr.attr,
     NULL,
 };
 
 static struct attribute_group attr_group = {
     .attrs = attrs,
 };
 
 static struct kobject *fastchg_kobj;
 
 static int __init fastchgtoggle_init(void)
 {
     int ret;
     
     fastchg_kobj = kobject_create_and_add("fastchgtoggle", kernel_kobj);
     if (!fastchg_kobj)
         return -ENOMEM;
     
     ret = sysfs_create_group(fastchg_kobj, &attr_group);
     if (ret)
         kobject_put(fastchg_kobj);
     
     pr_info("Fast Charge Toggle initialized\n");
     return ret;
 }
 
 static void __exit fastchgtoggle_exit(void)
 {
     kobject_put(fastchg_kobj);
     pr_info("Fast Charge Toggle removed\n");
 }
 
 module_init(fastchgtoggle_init);
 module_exit(fastchgtoggle_exit);
 
 MODULE_LICENSE("GPL");
 MODULE_AUTHOR("KamiKaonashi");
 MODULE_DESCRIPTION("Simple Fast Charge Toggle");
