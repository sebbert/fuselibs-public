using Uno;

namespace Fuse.Reactive
{
	/** Utility base class that observes the first value of an `IObservable`.
	*/
	abstract class ValueObserver: IDisposable, IObserver
	{
		IDisposable _obsSub;
		IObservable _obs;

		public IObservable Observable { get { return _obs; } }

		protected void Subscribe(IObservable obs)
		{
			_obs = obs;
			_obsSub = obs.Subscribe(this);
		}

		protected void Unsubscribe()
		{
			if (_obsSub != null) _obsSub.Dispose();
			_obsSub = null;
			_obs = null;
		}

		public virtual void Dispose()
		{
			Unsubscribe();
		}

		protected abstract void PushData(object newValue);
		
		void IObserver.OnClear()
		{
			PushData(null);
		}

		void IObserver.OnSet(object newValue)
		{
			PushData(newValue);				
		}

		void IObserver.OnAdd(object addedValue)
		{
			PushData(_obs[0]);
		}

		void IObserver.OnNewAt(int index, object value)
		{
			PushData(_obs[0]);
		}

		void IObserver.OnFailed(string message)
		{
			
		}

		void IObserver.OnNewAll(IArray values)
		{
			if (values.Length > 0)
				PushData(_obs[0]);
		}

		void IObserver.OnRemoveAt(int index)
		{
			if (_obs.Length > 0)
				PushData(_obs[0]);
		}

		void IObserver.OnInsertAt(int index, object value)
		{
			PushData(_obs[0]);
		}
	}

	class ValueForwarder: ValueObserver
	{
		public interface IValueListener { void NewValue(object value); }

		IValueListener _listener;
		public ValueForwarder(IObservable obs, IValueListener listener)
		{
			_listener = listener;
			Subscribe(obs);
		}

		protected override void PushData(object newValue)
		{
			_listener.NewValue(newValue);
		}
	}
}
