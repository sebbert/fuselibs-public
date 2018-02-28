using Uno;
using Fuse;
using Fuse.Reactive;


namespace Fuse.Models.Test
{
	public class ObservableArrayProxy : Element, IObserver
	{
		IDisposable _sub;
		ISubscription _subTwoWay;
		IObservableArray _obs;
		public IObservableArray Observable
		{
			get { return _obs; }
			set
			{
				if (_obs == value)
					return;
				
				_obs = value;

				if (IsRootingCompleted)
					Subscribe();
			}
		}

		bool HasSubscription { get { return _sub != null; } }

		void Subscribe()
		{
			Unsubscribe();
			
			_sub = _obs.Subscribe(this);
			_subTwoWay = _sub as ISubscription;
		}

		void Unsubscribe()
		{
			if (HasSubscription)
			{
				_sub.Dispose();
				_sub = null;
				_subTwoWay = null;
			}
		}

		protected override void OnRooted()
		{
			base.OnRooted();
			if (!HasSubscription)
				Subscribe();
		}

		protected override void OnUnrooted()
		{
			Unsubscribe();
			base.OnUnrooted();
		}

		void AssertCanWriteBack()
		{
			if (_subTwoWay == null)
				throw new InvalidOperationException("The observable does not support write-back");
		}

		public void ClearExclusive()
		{
			AssertCanWriteBack();
			_subTwoWay.ClearExclusive();
		}

		public void SetExclusive(object value)
		{
			AssertCanWriteBack();
			_subTwoWay.SetExclusive(value);
		}

		public void ReplaceAllExclusive(IArray values)
		{
			AssertCanWriteBack();
			_subTwoWay.ReplaceAllExclusive(values);
		}

		public Action Clear { get; set; }
		public Action<IArray> NewAll { get; set; }
		public Action<int, object> NewAt { get; set; }
		public Action<object> Set { get; set; }
		public Action<object> Add { get; set; }
		public Action<int> RemoveAt { get; set; }
		public Action<int, object> InsertAt { get; set; }
		public Action<string> Failed { get; set; }

		void IObserver.OnClear()
		{
			if (Clear != null)
				Clear();
		}

		void IObserver.OnNewAll(IArray values)
		{
			if (NewAll != null)
				NewAll(values);
		}

		void IObserver.OnNewAt(int index, object newValue)
		{
			if (NewAt != null)
				NewAt(index, newValue);
		}

		void IObserver.OnSet(object newValue)
		{
			if (Set != null)
				Set(newValue);
		}

		void IObserver.OnAdd(object addedValue)
		{
			if (Add != null)
				Add(addedValue);
		}

		void IObserver.OnRemoveAt(int index)
		{
			if (RemoveAt != null)
				RemoveAt(index);
		}

		void IObserver.OnInsertAt(int index, object value)
		{
			if (InsertAt != null)
				InsertAt(index, value);
		}

		void IObserver.OnFailed(string message)
		{
			if (Failed != null)
				Failed(message);
		}

		protected override float2 GetContentSize( LayoutParams lp )
		{
			return float2(0);
		}
		
		protected override void OnDraw(Fuse.DrawContext dc) { }
	}
}
