function [ ActiveCode ] = HandleCode( Code )
%% ���ݴ�����ڻ����봦��õ���Ӧ�Ļ�Ծ�ڻ���Լ�Ĵ���

is_letter = isletter(Code);   % �ж��Ƿ�Ϊ��ĸ

if length(Code) == 10
    ActiveCode = strcat(Code(1:2),Code(7:end));
elseif length(Code) == 9
    if is_letter(2) == 1
        ActiveCode = strcat(Code(1:2),Code(6:end));
    else 
        ActiveCode = strcat(Code(1),Code(6:end));
    end
else
    error('������ı�Ĵ�������');
end

end

