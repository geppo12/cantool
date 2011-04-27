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

unit ULogOptions;

interface

type
  TLogOptions = class
	  private
    class var FInstance: TLogOptions;
    var
    FCrc: Boolean;
    FDoublePar: Boolean;

    public
    class constructor Create;
    class destructor Destroy;
    class property Instance: TLogOptions read FInstance;
    property Crc: Boolean read FCrc write FCrc;
    property DoublePar: Boolean read FDoublePar write FDoublePar;
  end;

implementation

class constructor TLogOptions.Create;
begin
  FInstance := TLogOptions.Create;
  FInstance.FCrc := false;
  FInstance.FDoublePar := false;
end;

class destructor TLogOptions.Destroy;
begin
  FInstance.Free;
end;

end.
