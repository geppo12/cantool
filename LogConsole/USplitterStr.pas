{
	 Copyright 2011 Giuseppe Monteleone

	 This file is part of 'Ninjeppo Can Tool'

	 'Ninjeppo Can Tool' is free software: you can redistribute
	 it and/or modify it under the terms of the GNU General Public
	 License versione 2, as published by the Free Software Foundation

 	 THIS SOFTWARE IS PROVIDED BY GIUSEPPE MONTELEONE ``AS IS'' AND ANY
 	 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
	 PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL GIUSEPPE MONTELEONE BE
	 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
	 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
	 OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
	 OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
	 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
	 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	 You should have received a copy of the GNU General Public License
	 along with 'Ninjeppo Can Tool'. If not, see <http://www.gnu.org/licenses/>.
}
unit USplitterStr;

interface

uses
  Types;

type

  TSplitterStr = class
    private
    FArray: TStringDynArray;

    public
    procedure Parse(AStr: string);
    function GetArgument(AIdx: Integer): string;
    function LineFromArg(AIdx: Integer): string;
    function GetCount(): Integer;
  end;

implementation

uses
  SysUtils,
  StrUtils;


procedure TSplitterStr.Parse(AStr: string);
begin
  FArray := SplitString(AStr,' ');
end;

function TSplitterStr.GetArgument(AIdx: Integer): string;
begin
  Result := '';
	if AIdx < Length(FArray) then
		Result := Trim(FArray[AIdx]);
end;

function TSplitterStr.LineFromArg(AIdx: Integer): string;
var
  LIdx: Integer;
begin
	Result := GetArgument(AIdx);

	for LIdx := AIdx+1 to GetCount-1 do
		Result := Result + ' ' + GetArgument(LIdx);
end;


function TSplitterStr.GetCount: Integer;
begin
	Result := Length(FArray);
end;

end.
