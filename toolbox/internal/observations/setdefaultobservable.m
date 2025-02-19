function setdefaultobservable(varargin)
%SETDEFAULTOBSERVABLE Set a default observable
%   SETDEFAULTOBSERVABLE is a helper function allowing to specify a set of 
%   default observables. When a default observable is set, it is possible
%   to simulate virtual individuals without specifying observables in the 
%   Sampling object, in which case the default observables will be used.
%
%   SETDEFAULTOBSERVABLE(OBS) sets Observable object OBS as the default 
%   observable.
%   
%   SETDEFAULTOBSERVABLE([]) clears the default observable.
%   
%   SETDEFAULTOBSERVABLE(...) with any other input calls getPBPKobservable
%   to determine which observables to set as default. As a special case,
%   SETDEFAULTOBSERVABLE() uses the defaults specified there.   
%
%   See also Observable, PBPKobservables.

    if nargin == 1 && (isempty(varargin{1}) || isa(varargin{1},'Observable'))
        obs = varargin{1};
    else
        obs = PBPKobservables(varargin{:});
    end
    setoptcompphysiol('DefaultObservable',obs);

end

