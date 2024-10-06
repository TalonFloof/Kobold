# Kobold License - v1.0

***THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS LICENSE DOCUMENT.***
***ANY USE, REDISTRIBUTION, OR MODIFICATION, BOTH PUBLIC AND PRIVATE, CONSTITUTES RECIPIENT'S ACCEPTANCE WITH ALL TERMS SPECIFIED WITHIN THIS DOCUMENT.***

*Copyright © 2024 TalonFloof and Contributors.*

## Preamble

Kobold is an open-source project that encourages experimentation and usage of it. We believe that by making software publicly viewable, that it may encourage and strengthen both our growth and allow for others to use its ideas in one's own works. However, in order to protect original property, while allowing flexibility of redistribution and modification, it becomes necessary to include a license document to ensure that the author(s) receive the credit they deserve as well as any other conditions they believe are just in order to protect their property.

Many other licenses were considered prior to this one, and the decision to write a new license from scratch was not one that was easily done. However, we believe that by creating this document, that we will be able to protect what is ours while still providing lots of flexibility with others who want to modify and/or redistribute this program.  
We also hope that we can use this document to see other software use this license to protect their works as well.  
However, we are by no means lawyers, and it is possible that this document may not be perfect. If you believe there are any issues or loopholes that we did not find, we encourage you to open a pull request at https://github.com/TalonFloof/Kobold. This license is by no means a complete and ratified document and we are always open to have others help improve this document.

We have built this license to be organized and easy to read, we encourage you to take a glance at the terms to understand what can and cannot be done.

## 1. Definitions

- "**License**" refers to this document, as well as all of the terms and conditions stated within it.
- "**Source**" refers to the preferred form for making modifications, including but not limited to software source code, documentation source, and configuration files.
- "**Object**" refers to any non-source form that is the result of transformation or translation from sources. This includes compiled object code, generated documentation, and conversions to other media types.
- "**Contributor**" refers to any individual or legal entity that creates, contributes to the creation of, or owns the software this license is covering.
- "**Contribution**" refers to the Software of a particular Contributor.
- "**Recipient**" refers to anyone who receives the Program under this Agreement, including all Contributors.
- "**Secondary License**" refers to any licenses outside of the Kobold License, such as the MIT License, the GPL family of licenses, etc. This includes licenses and copyright to Proprietry and Closed-Source software.
- "**You**" (or "**Your**") refers to an individual or Legal Entity exercising permissions granted by this License.

## 2. Redistribution and Modification

A Contributor who chooses to modify and/or redistribute any Source or Object form of this Software outside of the original repository must comply with the following conditions listed below:

- Any Redistributions of any Sources must retain this document within the source code.
- Any Redistributions of the complete binary form of this Software's Objects (meaning the final compliled form of the Software) must contain this document and/or a copyright notice that notes that this Software is licensed under the Kobold License, within its documentation or any other form of material accessible to the user. If you so choose to, you may only include the copyright notice and omit this document as long as you provide a hyperlink to this document within your notice. (See **EXHIBIT A**  for an example)
- If the Sources are modified from the original works, then any Recipients who have access to the Object form of this Software have the right to view modified Sources Contributors made; Contributors must disclose modified Sources and have it be accessible in some form. (ex. via websites like GitHub, from package managers, etc.) Unmodified code on Redistributions is exempt from this.
- All Redistributions must use this same license as the original distribution. Only Contributors of the original distribution may change the license, and all derivatives must use the same terms as the version it is derived from; the Contributor cannot change it.

Failure to comply with listed terms violates the Contributors' Copyright to the Software this license covers. This license will also be void, and all rights specified will be automatically terminated.

Sources that are under a Secondary License do not fall under these conditions but rather are under their respective License unless certain files are exempt from the Secondary License. (see **3**)

## 3. Secondary Licenses

If a directory contains a License file other than this one (also known as a Secondary License), than the files within that directory and its subdirectories falls under that License rather than this one. If a Source file contains a copyright notice for another license, then that specific Source file falls under that Secondary License.

If you choose to put a Source file under this License rather than a Secondary License specified within that Secondary License's directory or its subdirectories, you may add a list specifying which files are not part of that Secondary License, but rather are part of this license. (see **EXHIBIT B** for how to do this). If you choose to not use the exemption notice list, or cannot due to conditions within the Secondary License, then you may also add a copyright notice within the file(s), which will still exempt it from the Secondary License. (see **EXHIBIT A**)

Objects and Compiled forms of the program do not require this to be done, though the terms and conditions of those licenses must still be complied with.

## 4. Object, Library, and Module Usage

Software under the Kobold License is allowed to be linked, and/or interact with software that has a Secondary License and vice versa given it follows its terms and conditions.

Secondary Licensed Software linked with Kobold Licensed Software still retains that software's Secondary License and copyright; linking Kobold Licensed Objects with non-kobold Licensed Objects does not force that software to use the Kobold License, it may still continue to retain its own copyright, though it must still give attribution since the Objects are linked to the final binary (implying it was statically linked). (See **section 2**)

For instance, if you are making a piece of Software under the MIT License, and you use a library licensed under the Kobold License, that software you wrote in the MIT License is still under the MIT License, while the Objects under the Kobold License are still under the Kobold License. The final linked binary version (assuming you statically linked the Kobold-licensed Objects) of this software is **your property** and is still under the MIT License, however you must still follow **section 2** in order to use the Kobold-licensed Software since it is statically linked to the binary. 

**Section 2** does not apply if Kobold-licensed Objects are dynamically linked to Secondary Licensed software since the binary is linked during runtime and not at compile-time, though documenting that the library is used would be appreciated, but not required.

## 5. No Warranty
***Except as expressively set forth in this License, the Software is provided “as is”, without warranty of any kind, either expressed or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement.*** Recipients of the software must decide what the appropriate use of this software is and must be willing to accept any possible risks if one decides to use or modify it under the conditions of this License.

## 6. Disclaimer of Liability
***Except as expressively set forth in this License, neither Recipient nor any Contributors shall have any liability for any direct, indirect, incidental, special, exemplary, or consequential damages (including, but not limited to, procurement of substitute goods or services; loss of use, data, or profits; or business interruption), however caused and on any theory of liability, whether in contract, strict liability, or tort (including negligence or otherwise) arising in any way out of the use or distribution of the Software or the exercise of any rights granted hereunder, even if advised of the possibility of such damages.***

---
***END OF TERMS AND CONDITIONS***

## EXHIBIT A: Copyright Notice
Within Source Code:
```c
/* Copyright (C) [year range] [copyright holder]
 * 
 * This Source file is licensed under the Kobold License.
 * The original and derivative forms of this file must follow its terms and conditions when/if distributed.
 * 
 * You should have received a copy of the original Kobold License file containing more info on these terms.
 * If you did not, then you may view <https://github.com/TalonFloof/Kobold/blob/main/LICENSE.md> for more information on the license.
 */
```

Software Copyright Notice:
```
Copyright (C) [year range] [copyright holder]
This software is open-source can may be redistributed
under certain conditions specified within the Kobold License.

You should have received a copy of the original Kobold License file containing more info on these terms.
If you did not, then you may view <https://github.com/TalonFloof/Kobold/blob/main/LICENSE.md> for more information on the license.
```

You aren't required to strictly follow the given software copyright notice, rather this is a template that you can use that satisfies **section 2**.

## EXHIBIT B: Secondary License Exemption Example
TXT Version:
```
=== KOBOLD LICENSE NOTICE ===
The listed files below are not covered under the [Insert License Name] License, but rather, are part of the Kobold License.

You should have received a copy of the license alongside the Sources provided here. If you did not, please see <https://github.com/TalonFloof/Kobold/blob/main/LICENSE.md> for more info.

= EXEMPTION LIST:
[Insert File List Starting Here]
```
Markdown Version:
```md
# Kobold License Notice
The listed files below are not covered under the [Insert License Name] License, but rather, are part of the Kobold License.

You should have received a copy of the license alongside the Sources provided here. If you did not, please see https://github.com/TalonFloof/Kobold/blob/main/LICENSE.md for more info.

## Exemption List
- [Insert File List Starting Here]
```

Wildcards (ex. `*.zig`) may be used to include all files that contain a certain extension within the directory and its subdirectories.

These are templates, you are allowed to create versions for other markup languages if you need to do so.
