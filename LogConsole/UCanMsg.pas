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

unit UCanMsg;

interface

Uses
  Generics.Collections;

type
  TCanMsg = record
    public
    ecmTime: Int64;
    ecmID: Cardinal;
    ecmLen: Cardinal;
    ecmData: array [0..7] of Byte;
    // for debug
    function ToString: string;
  end;

  TCanMsgQueue = TQueue<TCanMsg>;

implementation

uses
  SysUtils,
  StrUtils;

{$REGION 'TCanMsg'}
function TCanMsg.ToString: string;
var
  I: Integer;
begin
  Result := Format('ID=0x%08X L=%d D=',[ecmId,ecmLen]);

  for I := 0 to ecmLen - 1 do
    Result := Result + Format('%.2X.',[ecmData[i]]);

  Result := LeftStr(Result,Length(Result)-1);
end;

{$ENDREGION}

end.
