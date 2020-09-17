import subprocess, shlex , sys, re
from quantiphy import Quantity


def de_word_wrap_scs(fin):
    """ remove the wordwrappings --> one command is one line """
    f = fin.split('.') 
    f_tmp = '.'.join(f[:-1]) + "_tmp." + f[-1]
    cmd = shlex.split(fr"perl -p -e 's/\\\n\t*/ /; s/ +/ /g' {fin}")
    with open(f_tmp,'w+') as outfile:
        subprocess.run(cmd, stdout=outfile)
    return f_tmp

def get_condition_from_scs(fin):
    """ Takes an scs file and extracts simulation conditions. 
        Returns a dict of section, temp, devcie_name, nf, freq_of_sp_sim, vgs, vds, vbs.
    """

    section, temp, vgs, vds, vbs, freq, dev, nf = [None]*8

    with open(de_word_wrap_scs(fin),'r') as fin:
        for line in fin:
            if re.match("include", line):
                m = re.match(" section\s*=\s*(.*)", line)
                if m:
                    section = m.group(1)
            if re.match("parameters", line):
                m_vgs = re.search(" vgs=([0-9.]*[a-zA-Z]?) ", line)
                m_vds = re.search(" vds=([0-9.]*[a-zA-Z]?) ", line)
                m_vbs = re.search(" vbs=([0-9.]*[a-zA-Z]?) ", line)
                assert all([m_vgs, m_vds, m_vbs]), f"At least one terminal voltage was not found. VG={m_vgs}, VD={m_vds}, VB={m_vbs}"
                vgs = Quantity(m_vgs.group(1)).real
                vds = Quantity(m_vds.group(1)).real
                vbs = Quantity(m_vbs.group(1)).real
            if re.match("[^ ]* sp ", line):
                # NOTE: freq is only used if a variable is swept. By frequency sweep no freq is written in the sp spectre command
                m_freq = re.search(" freq=([0-9.]*[a-zA-Z]?) ", line)
                # assert m_freq, "No S-param freq was found --> probably freq is swept. The program expects a paramteric sweep at a given freq"
                if m_freq:
                    freq = Quantity(m_freq.group(1)).real
                else:
                    freq = None
            if re.match("[^ ]* options", line):
                m_temp = re.search(" temp=([0-9.]*) ", line)
                # assert m_temp, "No temperature information was found in the scs file"
                if m_temp:
                    temp = float(m_temp.group(1))
            if re.match("subckt ", line):
                line2 = next(fin)
                # m_nf  = re.search(" nf=([0-9.]*[a-zA-Z]?) ", line2)
                m_nf  = re.search(" nf=([0-9]*) ", line2)
                m_dev = re.search("[^ ]* \([^)]*\) ([^ ]*) ", line2)
                assert m_dev, "Device modelname could not be determined"
                assert m_nf, "Number of fingers could not be determined"
                # nf = Quantity(m_nf.group(1)).real
                nf = int(m_nf.group(1))
                dev = m_dev.group(1)
    return {'device': dev, 'temp': temp, 'nf':nf, 'section':section, 
            'freq':freq, 'vgs':vgs, 'vds':vds, 'vbs':vbs}

if __name__ == "__main__":
    print(get_condition_from_scs(sys.argv[1]))
