using Uno.Collections;
using Uno;
using Fuse;
using Fuse.Scripting;
using Fuse.Reactive;

namespace Fuse.Scripting.JavaScript
{
	class TreeArray : ArrayMirror, IObservableArray
	{
		internal TreeArray(Scripting.Array arr): base(arr) {}

		public IDisposable Subscribe(Fuse.Reactive.IObserver observer)
		{
			return new ArraySubscription(this, observer);
		}

		internal class ArraySubscription: Subscription, ISubscription
		{
			readonly Fuse.Reactive.IObserver _observer;
			int _origin = TreeSubscriptionCounter.GetNext();

			public ArraySubscription(ArrayMirror am, Fuse.Reactive.IObserver observer): base(am)
			{
				_observer = observer;
			}

			public void OnReplaceAt(int index, object newValue, int origin)
			{
				if (_origin != origin)
					_observer.OnNewAt(index, newValue);

				var next = Next as ArraySubscription;
				if (next != null) next.OnReplaceAt(index, newValue, origin);
			}

			public void OnAdd(object newValue, int origin)
			{
				if (_origin != origin)
					_observer.OnAdd(newValue);

				var next = Next as ArraySubscription;
				if (next != null) next.OnAdd(newValue, origin);
			}

			public void OnInsertAt(int index, object newValue, int origin)
			{
				if (_origin != origin)
					_observer.OnInsertAt(index, newValue);
				var next = Next as ArraySubscription;
				if (next != null) next.OnInsertAt(index, newValue, origin);
			}

			public void OnRemoveAt(int index, int origin)
			{
				if (_origin != origin)
					_observer.OnRemoveAt(index);
				var next = Next as ArraySubscription;
				if (next != null) next.OnRemoveAt(index, origin);
			}

			public void OnReplaceAll(IArray values, int origin)
			{
				if (_origin != origin) _observer.OnNewAll(values);

				var next = Next as ArraySubscription;
				if (next != null) next.OnReplaceAll(values, origin);
			}

			class ReplaceAllOperation
			{
				Scripting.Array _target;
				IArray _newValues;
				int _origin;

				public ReplaceAllOperation(Scripting.Array target, IArray newValues, int origin)
				{
					_target = target;
					_newValues = newValues;
					_origin = origin;
				}

				public void Perform(Scripting.Context context)
				{
					var nv = new object[_newValues.Length];
					for (var i = 0; i < _newValues.Length; ++i) {
						nv[i] = context.Unwrap(_newValues[i]);
					}
					var newValuesJs = context.NewArray(nv);

					var replaceAllFn = (Scripting.Function) context.Evaluate("replaceAll",
						"(function(array, values, origin) {" +
							"if ('__fuse_replaceAll' in array) array.__fuse_replaceAll(values, origin);" +
							"else {"+
								"array.length = 0;"+
								"Array.prototype.push.apply(array, values);"+
							"}"+ 
						"})");

					replaceAllFn.Call(context, _target, newValuesJs, _origin);
				}
			}


			public void ReplaceAllExclusive(Scripting.Context context, IArray values)
			{
				var ta = SubscriptionSubject as TreeArray;

				var replaceAll = new ReplaceAllOperation((Scripting.Array)ta.Raw, values, _origin);
				replaceAll.Perform(context);

				UpdateManager.PostAction(new ReplaceAllOnUIThreadClosure(ta, values, _origin).Perform);
			}

			void ReplaceAllExclusive(IArray values)
			{
				var ta = SubscriptionSubject as TreeArray;

				var worker = Fuse.Reactive.JavaScript.Worker;
				var replaceAll = new ReplaceAllOperation((Scripting.Array)ta.Raw, values, _origin);
				worker.Invoke(replaceAll.Perform);

				ta.ReplaceAll(values, _origin);
			}

			void ISubscription.ClearExclusive()
			{
				ReplaceAllExclusive(new SimpleArray());
			}

			public void ClearExclusive(Scripting.Context context)
			{
				ReplaceAllExclusive(context, new SimpleArray());
			}

			void ISubscription.SetExclusive(object newValue)
			{
				ReplaceAllExclusive(new SimpleArray(newValue));
			}

			public void SetExclusive(Scripting.Context context, object newValue)
			{
				ReplaceAllExclusive(context, new SimpleArray(newValue));
			}

			void ISubscription.ReplaceAllExclusive(IArray values)
			{
				ReplaceAllExclusive(values);
			}

			class SimpleArray : IArray
			{
				object[] _values;

				public SimpleArray(params object[] values)
				{
					_values = values;
				}

				public int Length { get { return _values.Length; } }
				public object this[int index]
				{
					get
					{
						return _values[index];
					}
				}
			}
		}

		class ReplaceAllOnUIThreadClosure
		{
			TreeArray _treeArray;
			IArray _newValues;
			int _origin;

			public ReplaceAllOnUIThreadClosure(TreeArray treeArray, IArray newValues, int origin)
			{
				_treeArray = treeArray;
				_newValues = newValues;
				_origin = origin;
			}

			public void Perform()
			{
				_treeArray.ReplaceAll(_newValues, _origin);
			}
		}

		internal void ReplaceAll(IArray newValues, int origin)
		{
			for (var i = 0; i < _items.Count; ++i)
			{
				ValueMirror.Unsubscribe(_items[i]);
			}

			_items.Clear();

			for (var i = 0; i < newValues.Length; ++i)
			{
				_items.Add(newValues[i]);
			}

			var sub = Subscribers as ArraySubscription;
			if (sub != null)
				sub.OnReplaceAll(newValues, origin);
		}

		internal void Set(int index, object newValue, int origin)
		{
			ValueMirror.Unsubscribe(_items[index]);

			_items[index] = newValue;

			var sub = Subscribers as ArraySubscription;
			if (sub != null)
				sub.OnReplaceAt(index, newValue, origin);
		}

		internal void Add(object value, int origin)
		{
			_items.Add(value);
			var sub = Subscribers as ArraySubscription;
			if (sub != null)
				sub.OnAdd(value, origin);
		}

		internal void InsertAt(int index, object value, int origin)
		{
			_items.Insert(index, value);
			var sub = Subscribers as ArraySubscription;
			if (sub != null)
				sub.OnInsertAt(index, value, origin);
		}

		internal void RemoveAt(int index, int origin)
		{
			_items.RemoveAt(index);
			var sub = Subscribers as ArraySubscription;
			if (sub != null)
				sub.OnRemoveAt(index, origin);
		}
	}
}
