function str = helpPopupStr(cls)
%HELPPOPUPSTR Clickable link to class help in char format

    str = sprintf('<a href="matlab:helpPopup %s">%s</a>',cls,cls);

end