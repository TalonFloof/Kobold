use spin::{Once, RwLock};
use alloc::{collections::btree_map::BTreeMap, string::String, sync::Arc};

pub trait Scheme: Send + Sync + 'static {

}

static SCHEME_LIST: Once<RwLock<BTreeMap<String, Arc<dyn Scheme>>>> = Once::new();