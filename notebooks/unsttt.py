try:
    from warnings import PendingDeprecationWarning
except ImportError:
    from warnings import DeprecationWarning as PendingDeprecationWarning