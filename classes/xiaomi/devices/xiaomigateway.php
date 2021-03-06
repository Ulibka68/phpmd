<?php

/**
 * Шлюз Xiaomi
 */

namespace Xiaomi\Devices;

class XiaomiGateway extends AbstractDevice implements \SmartHome\SensorsInterface {
    
    const MULTICAST_ADDRESS='224.0.0.50';
    const MULTICAST_PORT=9898;

    protected $ip;
    private $bright;
    private $rgb;
    private $token;
    protected $key;
    private $illumination;
    
    private $stream;
    
    public function __sleep() {
        return ['ip','bright','rgb','token','key','illumination','sid','model','voltage','updated'];
    }
    
    public function getInitDataList() {
        return ['ip'=>'IP адрес','key'=>'Пароль'];
    }

    public function getInitDataValues() {
        return ['ip'=>$this->ip,'key'=>$this->key];
    }

    public function update(\Xiaomi\XiaomiPacket $pkt) {
        $token=$pkt->getToken();
        if ($token!='') {
            $this->token=$token;
        }
        parent::update($pkt);
    }

    public function setKey($key) {
        $this->key=$key;
    }

    public function prepareCommand(array $cmd_data) {
        if (is_null($this->token)) {
            return false;
        }
        $cmd_data['key']=$this->makeSignature();
        $data=['cmd'=>'write'];
        $data['sid']=$this->sid;
        $data['short_id']=0;
        $data['model']=$this->model;
        $data['data']=json_encode($cmd_data);
        return json_encode($data);
    }

    protected function updateParam($param,$value) {
        switch ($param) {
            case "illumination":
                $this->setIllumination($value);
                break;
            case "rgb":
                $this->setRgb($value);
                break;
            case "ip":
                $this->ip=$value;
                break;
            case "proto_version":
                break;
            default:
                echo "$param => $value\n";
        }
    }

    private function setIllumination($value) {
        $last=$this->illumination;
        $this->illumination=$value;
        if($last!=$this->illumination) {
            $this->actions['illumination']=$value;
        }
    }

    private function setRgb($value) {
        $hex=dechex($value);
        if(strlen($hex)==7) {
            $hex='0'.$hex;
        }
        $parts=str_split($hex,2);
        if (sizeof($parts)!=4) {
            $this->bright=0;
            $this->rgb="FFFFFF";
            return;
        }
        $last_bright=$this->bright;
        $last_rgb=$this->rgb;
        $this->bright=hexdec($parts[0]);
        $this->rgb=$parts[1].$parts[2].$parts[3];
        if($last_bright!=$this->bright) {
            $this->actions['bright']=$this->bright;
        }
        if($last_rgb!=$this->rgb) {
            $this->actions['rgb']=$this->rgb;
        }
    }

    private function makeSignature() {
        $iv=hex2bin('17996d093d28ddb3ba695a2e6f58562e');
        $bin_data=base64_decode(openssl_encrypt($this->token,'AES-128-CBC',$this->key,OPENSSL_ZERO_PADDING,$iv));
        return bin2hex($bin_data);
    }

    public function getStream() {
        if(!is_null($this->stream)) {
            return $this->stream;
        }
        $this->stream=stream_socket_server("udp://0.0.0.0:".self::MULTICAST_PORT,$errno,$errstr,STREAM_SERVER_BIND);

        if (!$this->stream) {
            throw new Exception("$errstr ($errno)");
        }
        $socket=socket_import_stream($this->stream);
        if (!$socket) {
            throw new Exception('Unable to import stream.');
        }
        if (!socket_set_option($socket,SOL_SOCKET,SO_REUSEADDR,1)) {
            throw new Exception('Unable to enable SO_REUSEADDR');
        }
        if (!socket_set_option($socket,IPPROTO_IP,MCAST_JOIN_GROUP,['group'=>self::MULTICAST_ADDRESS,'interface'=>0])) {
            throw new Exception('Unable to join multicast group');
        }
        return $this->stream;
    }
    
    public function closeStream() {
        if(!is_null($this->stream)) {
            fclose($this->stream);
            $this->stream=null;
        }
    }
    
    public function sendMessage($message) {
        $stream=$this->getStream();
        stream_socket_sendto($stream,$message,0,$this->ip.':'.self::MULTICAST_PORT);
    }
    
    public function getBright() {
        return $this->bright;
    }
    
    public function getRGB() {
        return $this->rgb;
    }
    
    public function getIllumination() {
        return $this->illumination;
    }

    public function getDeviceDescription() {
        return "Xiaomi Mi Smart Multifunctional Gateway";
    }

    public function getDeviceStatus() {
        $result=[];
        if(!is_null($this->bright)) {
            $result[]=$this->bright==0?"Подсветка выключена":"Яркоть подсветки ".$this->bright.'%, цвет #'.$this->rgb.'.';
        }
        if($this->illumination) {
            $result[]='Датчик света: '.$this->illumination.'.';
        }
        return join(' ',$result);
    }

    public function getDeviceIndicators(): array {
        return [];
    }

    public function getDeviceMeters(): array {
        return ['illumination'=>'Датчик освещённости'];
    }

}
